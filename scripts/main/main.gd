extends Node2D
class_name Main

## Orquestador principal del MVP: estados (inicio / juego / pausa / fin),
## spawn progresivo de oleadas, pausa y transiciones de partida.

const ENEMY_GRUNT := preload("res://scenes/enemies/enemy_grunt.tscn")
const ENEMY_WEAVER := preload("res://scenes/enemies/enemy_weaver.tscn")
const ENEMY_DIVER := preload("res://scenes/enemies/enemy_diver.tscn")
const ENEMY_SNIPER := preload("res://scenes/enemies/enemy_sniper.tscn")
const BOSS := preload("res://scenes/bosses/boss_01.tscn")
const BOSS2 := preload("res://scenes/bosses/boss_02.tscn")
const POWERUP := preload("res://scenes/items/powerup.tscn")
const EXPLOSION := preload("res://scenes/effects/explosion.tscn")

## Oleadas por ciclo. Tras completar la última aparece un jefe; al vencerlo sube
## la dificultad y comienza un ciclo nuevo (la partida es infinita).
const WAVES_PER_CYCLE := 10

## Probabilidad de soltar una mejora al matar un enemigo y "compasión" (número
## máximo de bajas sin drop para garantizar que aparezcan).
const DROP_CHANCE := 0.12
const DROP_PITY := 14
## Daño de la bomba a cada enemigo en pantalla.
const BOMB_DAMAGE := 3
## Amplitud máxima del sacudón de cámara, en píxeles.
const SHAKE_MAX := 15.0
## Velocidad con que se disipa el sacudón (unidades de trauma por segundo).
const SHAKE_DECAY := 2.6
## Ventana para encadenar bajas (segundos) y puntos extra por cada baja de la racha.
const COMBO_WINDOW := 2.2
const COMBO_BONUS := 2

@onready var starfield: Starfield = $World/Starfield
@onready var enemies_root: Node2D = $World/Enemies
@onready var bullets_root: Node2D = $World/Bullets
@onready var items_root: Node2D = $World/Items
@onready var effects_root: Node2D = $World/Effects
@onready var camera: Camera2D = $World/Camera2D
@onready var player: Player = $World/Player
@onready var hud: HUD = $HUD

enum State { START, PLAYING, GAMEOVER, VICTORY }  # VICTORY reservado (modo infinito)

var state: int = State.START

var _pending: Array = []   # specs pendientes {scene, x, t}
var _elapsed: float = 0.0  # tiempo desde el inicio de la oleada actual
var _alive: int = 0        # enemigos vivos de la oleada actual
var _wave_in_cycle: int = 0  # 0 .. WAVES_PER_CYCLE-1
var _cycle: int = 0          # nivel de dificultad (sube tras cada jefe)
var _intermission: float = -1.0  # countdown; <0 = inactivo
var _boss_spawned: bool = false
var _after_boss: bool = false    # la próxima pausa arranca un ciclo nuevo
var _boss: Node = null
var _kills_since_drop: int = 0
var _shake_trauma: float = 0.0
var _combo: int = 0
var _combo_timer: float = 0.0

func _ready() -> void:
	GameManager.game_running = false
	GameManager.game_over.connect(_on_game_over)
	GameManager.shake_requested.connect(_on_shake_requested)
	GameManager.lives_changed.connect(_on_lives_changed)
	hud.bomb_pressed.connect(_use_bomb)
	hud.pause_pressed.connect(toggle_pause)
	hud.start_requested.connect(_on_start_requested)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	enter_start()
	_attach_test_harness_if_requested()

## Adapta la cámara al tamaño real del viewport (pantallas altas 20:9 con
## `stretch/aspect=expand` y ventanas redimensionadas en PC).
func _on_viewport_resized() -> void:
	if camera:
		camera.position = get_viewport_rect().size * 0.5
	if starfield:
		starfield.set_view_size(get_viewport_rect().size)

## Ancho útil del área de juego según el viewport real (no 360 fijo).
func _field_width() -> float:
	return get_viewport_rect().size.x

# ---------------------------------------------------------------------------
# Estados
# ---------------------------------------------------------------------------
func enter_start() -> void:
	state = State.START
	GameManager.game_running = false
	set_paused(false)
	_reset_shake()
	_reset_combo()
	player.visible = false
	_clear_world()
	_boss = null
	_boss_spawned = false
	_after_boss = false
	_wave_in_cycle = 0
	_cycle = 0
	starfield.set_cycle(0)
	hud.hide_boss()
	hud.show_start(GameManager.high_score)
	AudioManager.stop_music()

func start_game() -> void:
	GameManager.high_score = SaveManager.get_high_score()
	GameManager.start_game()
	state = State.PLAYING
	set_paused(false)
	_reset_shake()
	_reset_combo()
	var vp := get_viewport_rect().size
	player.position = Vector2(vp.x * 0.5, vp.y - 70.0)
	player.reset()
	player.visible = true
	_wave_in_cycle = 0
	_cycle = 0
	starfield.set_cycle(0)
	_after_boss = false
	_intermission = -1.0
	_boss = null
	_boss_spawned = false
	_kills_since_drop = 0
	hud.hide_boss()
	_begin_wave()
	hud.show_playing()
	AudioManager.play_music("theme")

## El menú de inicio eligió dificultad: se fija y arranca la partida.
func _on_start_requested(difficulty: int) -> void:
	GameManager.set_difficulty(difficulty)
	start_game()

func set_paused(value: bool) -> void:
	get_tree().paused = value

func toggle_pause() -> void:
	if state != State.PLAYING:
		return
	var now_paused := not get_tree().paused
	set_paused(now_paused)
	if now_paused:
		hud.show_pause()
	else:
		hud.show_playing()

# ---------------------------------------------------------------------------
# Oleadas
# ---------------------------------------------------------------------------
func _begin_wave() -> void:
	_pending = _build_wave()
	_alive = 0
	_elapsed = 0.0

## Genera la oleada actual eligiendo una formación según el avance dentro del
## ciclo. Cada ciclo repite las formaciones con más enemigos (dificultad).
func _build_wave() -> Array:
	var step := _wave_in_cycle
	var c := _cycle
	match step:
		0: return _pat_line(ENEMY_GRUNT, 4 + c, 56.0, 0.40, false)
		1: return _pat_vee(ENEMY_GRUNT, 5 + c, 0.34)
		2: return _pat_stream(ENEMY_WEAVER, 4 + c, 0.55)
		3: return _pat_line(ENEMY_WEAVER, 3 + c, 74.0, 0.50, true)
		4: return _pat_line(ENEMY_DIVER, 3 + c, 72.0, 0.55, false)
		5: return _pat_snipers(ENEMY_SNIPER, 2 + c)
		6: return _pat_vee(ENEMY_WEAVER, 4 + c, 0.45)
		7: return _pat_pincer(ENEMY_GRUNT, 4 + c, 0.30)
		8: return _pat_mixed(c)
		_: return _pat_swarm(c)

## Spec de un enemigo: escena, x de aparición, instante de aparición y ajustes
## opcionales por instancia (p. ej. `hover_y` del sniper).
func _spec(scene: PackedScene, x: float, t: float, overrides: Dictionary = {}) -> Dictionary:
	var s := {"scene": scene, "x": x, "t": t}
	if not overrides.is_empty():
		s["overrides"] = overrides
	return s

## Fila centrada (opcionalmente espejada para variar).
func _pat_line(scene: PackedScene, count: int, spacing: float, dt: float, alternate: bool) -> Array:
	var specs: Array = []
	var t := 0.0
	var w := _field_width()
	for i in count:
		var x := _centered_x(i, count, spacing)
		if alternate and i % 2 == 1:
			x = w - x
		specs.append(_spec(scene, x, t))
		t += dt
	return specs

## Formación en V: aparece primero el centro y luego los costados, de modo que la
## figura se abre a medida que descienden.
func _pat_vee(scene: PackedScene, count: int, dt: float) -> Array:
	var mid := (count - 1) * 0.5
	var order: Array = []
	for i in count:
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return absf(a - mid) < absf(b - mid))
	var specs: Array = []
	var t := 0.0
	for i in order:
		specs.append(_spec(scene, _centered_x(i, count, 46.0), t))
		t += dt
	return specs

## Flujo que entra alternando desde ambos costados.
func _pat_stream(scene: PackedScene, count: int, dt: float) -> Array:
	var specs: Array = []
	var t := 0.0
	var w := _field_width()
	for i in count:
		var side := i % 2
		var k := i / 2
		var x := (40.0 + k * 18.0) if side == 0 else ((w - 40.0) - k * 18.0)
		specs.append(_spec(scene, clampf(x, 28.0, w - 28.0), t))
		t += dt
	return specs

## Pinza: entran simultáneamente desde los dos bordes hacia el centro.
func _pat_pincer(scene: PackedScene, count: int, dt: float) -> Array:
	var specs: Array = []
	var t := 0.0
	var w := _field_width()
	for i in count:
		var side := i % 2
		var k := i / 2
		var x := (30.0 + k * 26.0) if side == 0 else ((w - 30.0) - k * 26.0)
		specs.append(_spec(scene, clampf(x, 26.0, w - 26.0), t))
		t += dt * 0.6
	return specs

## Francotiradores repartidos en distintas alturas de frenado.
func _pat_snipers(scene: PackedScene, count: int) -> Array:
	var specs: Array = []
	var t := 0.0
	for i in count:
		specs.append(_spec(scene, _centered_x(i, count, 92.0), t, {"hover_y": 120.0 + i * 48.0}))
		t += 0.7
	return specs

## Mezcla de grunts (en fila) y weavers (en flujo).
func _pat_mixed(c: int) -> Array:
	var specs := _pat_line(ENEMY_GRUNT, 3 + c, 60.0, 0.40, false)
	var weavers := _pat_stream(ENEMY_WEAVER, 2 + c, 0.55)
	for s in weavers:
		s["t"] += 1.4
	specs.append_array(weavers)
	return specs

## Enjambre de cierre del ciclo: grunts en V + divers en pinza + snipers.
func _pat_swarm(c: int) -> Array:
	var specs := _pat_vee(ENEMY_GRUNT, 5 + c, 0.28)
	var divers := _pat_pincer(ENEMY_DIVER, 2 + c, 0.40)
	for s in divers:
		s["t"] += 1.6
	specs.append_array(divers)
	var snipers := _pat_snipers(ENEMY_SNIPER, 1 + c)
	for s in snipers:
		s["t"] += 3.0
	specs.append_array(snipers)
	return specs

func _centered_x(i: int, count: int, spacing: float) -> float:
	var w := _field_width()
	var x := w * 0.5 + (float(i) - (float(count) - 1.0) * 0.5) * spacing
	return clampf(x, 28.0, w - 28.0)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if state != State.PLAYING:
		return
	_elapsed += delta
	_update_shake(delta)
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_reset_combo()

	# Spawn de la cola.
	while not _pending.is_empty() and _pending[0]["t"] <= _elapsed:
		var spec: Dictionary = _pending.pop_front()
		_spawn_enemy(spec)

	# Fin de oleada -> pequeña pausa antes de lo siguiente (oleada o jefe).
	if _pending.is_empty() and _alive <= 0 and _intermission < 0.0:
		_intermission = 1.6

	if _intermission >= 0.0:
		_intermission -= delta
		if _intermission < 0.0:
			_advance()

## Tras una pausa decide qué sigue: otra oleada del ciclo o el jefe.
func _advance() -> void:
	_intermission = -1.0
	if _after_boss:
		# Ciclo nuevo con la dificultad ya aumentada: oleada 0.
		_after_boss = false
		_begin_wave()
		return
	if _wave_in_cycle >= WAVES_PER_CYCLE - 1:
		_spawn_boss()
	else:
		_wave_in_cycle += 1
		_begin_wave()

func _spawn_enemy(spec: Dictionary) -> void:
	var e: Area2D = spec["scene"].instantiate()
	e.position = Vector2(spec["x"], -24.0)
	# Ajustes por instancia (p. ej. `hover_y` del sniper) antes de entrar al árbol.
	var overrides: Dictionary = spec.get("overrides", {})
	for k in overrides:
		if k in e:
			e.set(k, overrides[k])
	# Dificultad: sube con la oleada dentro del ciclo, con el ciclo y con el modo.
	e.health += GameManager.enemy_hp_bonus()
	e.speed = (e.speed + float(_wave_in_cycle) * 2.0 + float(_cycle) * 12.0) * GameManager.enemy_speed_mult()
	e.shoot_interval = maxf(2.0, (e.shoot_interval - float(_cycle) * 0.35) * GameManager.enemy_fire_mult())
	enemies_root.add_child(e)
	e.tree_exiting.connect(_on_enemy_exited)
	# Al morir (no al salir de pantalla) puede soltar una mejora.
	e.died.connect(_on_enemy_died.bind(e))
	_alive += 1

func _on_enemy_exited() -> void:
	_alive -= 1

# ---------------------------------------------------------------------------
# Mejoras (drops) y bombas
# ---------------------------------------------------------------------------
## Un enemigo fue destruido: quizá suelta un objeto. El `enemy` sigue vivo en el
## árbol en el momento de la señal (queue_free es diferido), así que se puede
## leer su posición.
func _on_enemy_died(_points: int, enemy: Node2D) -> void:
	if state != State.PLAYING:
		return
	# Racha: cada baja dentro de la ventana suma combo y puntos extra.
	_combo += 1
	_combo_timer = COMBO_WINDOW
	if _combo >= 2:
		GameManager.add_score((_combo - 1) * COMBO_BONUS)
	hud.show_combo(_combo)
	_kills_since_drop += 1
	if _kills_since_drop >= DROP_PITY or randf() < DROP_CHANCE * GameManager.drop_chance_mult():
		_kills_since_drop = 0
		_spawn_powerup(enemy.global_position)

## Termina la racha (se pierde la vida, muere el jefe, etc.).
func _reset_combo() -> void:
	_combo = 0
	_combo_timer = 0.0
	hud.hide_combo()

## Al perder una vida se corta la racha (convención arcade).
func _on_lives_changed(_lives: int) -> void:
	if _combo > 0:
		_reset_combo()

func _spawn_powerup(pos: Vector2) -> void:
	var pu: Area2D = POWERUP.instantiate()
	pu.kind = _roll_powerup_kind()
	pu.position = pos
	# El drop nace dentro de un callback de física (el enemigo muere por choque o
	# impacto), así que el alta se difiere para no alterar el servidor de física
	# durante el "flush" de consultas.
	items_root.add_child.call_deferred(pu)

func _roll_powerup_kind() -> int:
	var r := randf()
	if r < 0.45:
		return PowerUp.Kind.WEAPON
	if r < 0.80:
		return PowerUp.Kind.SHIELD
	return PowerUp.Kind.BOMB

## Gasta una bomba: limpia los proyectiles enemigos y daña a todos los enemigos
## en pantalla. Las balas del jugador (PlayerBullet) no se ven afectadas.
func _use_bomb() -> void:
	if state != State.PLAYING or get_tree().paused or not GameManager.game_running:
		return
	if not GameManager.use_bomb():
		return
	for b in bullets_root.get_children():
		if b is EnemyBullet:
			b.queue_free()
	for e in enemies_root.get_children():
		if e.has_method("take_damage"):
			e.take_damage(BOMB_DAMAGE)
	hud.flash()
	GameManager.request_shake(0.85)
	AudioManager.play_sfx("bomb")

# ---------------------------------------------------------------------------
# Sacudón de cámara
# ---------------------------------------------------------------------------
func _on_shake_requested(amount: float) -> void:
	_shake_trauma = clampf(_shake_trauma + amount, 0.0, 1.0)

## Aplica un desplazamiento aleatorio a la cámara que se disipa con el tiempo.
## El trauma se eleva al cuadrado para una caída más natural.
func _update_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake_trauma > 0.0:
		_shake_trauma = maxf(0.0, _shake_trauma - SHAKE_DECAY * delta)
		var amp := _shake_trauma * _shake_trauma * SHAKE_MAX
		camera.offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _reset_shake() -> void:
	_shake_trauma = 0.0
	if camera != null:
		camera.offset = Vector2.ZERO

# ---------------------------------------------------------------------------
# Jefe
# ---------------------------------------------------------------------------
func _spawn_boss() -> void:
	var boss_scene := BOSS
	if (_cycle % 2) == 1:
		boss_scene = BOSS2
	var boss: Area2D = boss_scene.instantiate()
	# Escalado de dificultad del jefe según el ciclo y el modo elegido.
	var hard_mult := 1.3 if GameManager.is_hard() else 1.0
	boss.health = int(round(float(boss.health + _cycle * 30) * hard_mult))
	boss.speed = (boss.speed + float(_cycle) * 8.0) * GameManager.enemy_speed_mult()
	boss.shoot_interval = maxf(1.0, (boss.shoot_interval - float(_cycle) * 0.25) * GameManager.enemy_fire_mult())
	if "minion_interval" in boss:
		boss.minion_interval = maxf(1.6, boss.minion_interval - float(_cycle) * 0.5)
	if "minions_per_spawn" in boss:
		boss.minions_per_spawn = mini(2 + _cycle, 5)
	if "minion_speed_bonus" in boss:
		boss.minion_speed_bonus = float(_cycle) * 15.0
	boss.position = Vector2(_field_width() * 0.5, -90.0)
	enemies_root.add_child(boss)
	boss.tree_exiting.connect(_on_enemy_exited)
	boss.died.connect(_on_boss_died)
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_boss_health_changed)
	_boss = boss
	_boss_spawned = true
	_alive += 1
	_pending.clear()
	hud.show_boss(boss.health)
	AudioManager.play_sfx("warning")
	AudioManager.play_music("boss")
	GameManager.request_shake(0.35)
	var boss_name: String = boss.boss_name if "boss_name" in boss else "JEFE"
	hud.show_warning("ADVERTENCIA", boss_name)
	# Frase característica del jefe, titilando sobre la partida.
	var intro: String = boss.intro_message if "intro_message" in boss else ""
	if intro != "":
		hud.show_message(intro, 4.0)
	# Vuelve a la partida cuando termina el aviso (sin borrar la barra del jefe).
	await get_tree().create_timer(2.0).timeout
	if state == State.PLAYING and not get_tree().paused:
		hud.show_playing()

func _on_boss_health_changed(current: int, maximum: int) -> void:
	hud.set_boss_hp(current, maximum)

## El jefe fue destruido: sube la dificultad y arranca un ciclo nuevo. La partida
## NO termina (modo infinito elegido).
func _on_boss_died(_points: int) -> void:
	var boss_pos: Vector2 = _boss.global_position if is_instance_valid(_boss) else Vector2(_field_width() * 0.5, 150.0)
	# Forma liberada del jefe (algunos jefes dejan un "alma" al caer).
	var soul_path: String = ""
	var soul_msg: String = ""
	if is_instance_valid(_boss):
		if "soul_texture_path" in _boss:
			soul_path = _boss.soul_texture_path
		if "soul_message" in _boss:
			soul_msg = _boss.soul_message
	_cycle += 1
	_wave_in_cycle = 0
	_boss_spawned = false
	_after_boss = true
	_clear_enemies()
	_pending.clear()
	_intermission = 2.2
	_reset_combo()
	starfield.set_cycle(_cycle)
	hud.hide_boss()
	# Espectáculo de destrucción: explosión grande, sacudón y estallidos en anillo.
	AudioManager.play_sfx("big_explosion")
	GameManager.request_shake(1.0)
	hud.flash()
	_spawn_death_burst(boss_pos)
	_spawn_boss_soul(boss_pos, soul_path, soul_msg)
	AudioManager.play_music("theme")
	_show_banner("NIVEL %d" % (_cycle + 1), 1.8)
	SaveManager.set_best_cycle(_cycle)

## Anillo de explosiones que se expande desde el jefe al ser destruido.
func _spawn_death_burst(center: Vector2) -> void:
	for i in 6:
		var angle := TAU * float(i) / 6.0
		var fx: Node2D = EXPLOSION.instantiate()
		fx.global_position = center + Vector2(cos(angle), sin(angle)) * 46.0
		fx.radius = 22.0
		fx.duration = 0.55
		effects_root.add_child(fx)
	# Un último fogonazo central, más grande.
	var core: Node2D = EXPLOSION.instantiate()
	core.global_position = center
	core.radius = 46.0
	core.duration = 0.7
	core.shard_count = 14
	effects_root.add_child(core)

## Cuando el jefe cae, a veces su forma poseída se libera: aparece flotando
## entre estrellitas y corazoncitos, con un mensaje de agradecimiento titilando.
## Es sólo decorativo: no colisiona ni interfiere con la partida.
func _spawn_boss_soul(center: Vector2, tex_path: String, message: String) -> void:
	if tex_path != "" and ResourceLoader.exists(tex_path):
		var soul := BossSoul.new()
		soul.texture = load(tex_path)
		soul.position = center
		effects_root.add_child(soul)
		AudioManager.play_sfx("angel")
	if message != "":
		hud.show_message(message, 6.5)

## Muestra un aviso centrado durante unos segundos y vuelve a la partida.
func _show_banner(msg: String, duration: float) -> void:
	hud.show_text(msg)
	await get_tree().create_timer(duration).timeout
	if state == State.PLAYING and not get_tree().paused:
		hud.show_playing()

# ---------------------------------------------------------------------------
# Fin de partida / limpieza
# ---------------------------------------------------------------------------
func _on_game_over() -> void:
	state = State.GAMEOVER
	GameManager.save_high_score()
	_reset_shake()
	_reset_combo()
	_clear_world()
	_boss = null
	player.visible = false
	hud.hide_boss()
	hud.show_game_over(GameManager.score, GameManager.high_score)
	AudioManager.stop_music()

func _clear_world() -> void:
	for container in [enemies_root, bullets_root, items_root, effects_root]:
		for c in container.get_children():
			c.queue_free()

## Libera sólo los enemigos (incluidas las navecitas del jefe).
func _clear_enemies() -> void:
	for c in enemies_root.get_children():
		c.queue_free()

# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		return
	if get_tree().paused:
		# En pausa, un toque/clic también reanuda.
		if _is_confirm(event):
			toggle_pause()
		return
	if state == State.PLAYING:
		if event.is_action_pressed("bomb"):
			_use_bomb()
		return
	if state == State.GAMEOVER:
		if _is_confirm(event):
			enter_start()

func _is_confirm(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	if event is InputEventScreenTouch and event.pressed:
		return true
	return false

# ---------------------------------------------------------------------------
# Soporte para la batería de pruebas (tests/test_harness.gd).
# Sólo se instala si se pasan argumentos de usuario por línea de comandos.
# ---------------------------------------------------------------------------
func debug_snapshot() -> Dictionary:
	return {
		"state": state,
		"wave": _wave_in_cycle,
		"cycle": _cycle,
		"alive": _alive,
		"enemies": enemies_root.get_child_count(),
		"bullets": bullets_root.get_child_count(),
		"elapsed": _elapsed,
		"score": GameManager.score,
		"lives": GameManager.lives,
		"boss": _boss != null,
	}

func _attach_test_harness_if_requested() -> void:
	var args := OS.get_cmdline_user_args()
	var known := ["autostart", "test_gameover", "test_save", "test_pause", "test_screenshot", "test_damage", "test_boss", "test_minions", "test_cycles", "test_enemies", "test_powerups", "test_audio", "test_difficulty", "render_music", "make_screenshots"]
	var wanted := false
	for a in known:
		if a in args:
			wanted = true
			break
	if not wanted:
		return
	var harness_script: Script = load("res://tests/test_harness.gd")
	if harness_script == null:
		return
	var harness: Node = harness_script.new()
	harness.set("main", self)
	add_child(harness)
