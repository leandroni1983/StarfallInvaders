extends Node

## TestHarness: batería de verificación automática del MVP.
##
## NO forma parte del juego jugable: Main sólo lo instancia cuando se pasan
## argumentos de usuario por línea de comandos (por ejemplo `-- autostart`).
## Ejemplos de uso (desde la raíz del proyecto):
##   godot --headless --quit-after 900 -- autostart
##   godot --headless --quit-after 600 -- autostart test_gameover
##   godot --headless --quit-after 300 -- test_save
##   godot --headless --quit-after 900 -- autostart test_pause
##   godot --quit-after 1200 -- autostart test_screenshot
##   godot --path . -- make_screenshots   (ventana real → build/screenshots/)

var main: Node = null

var _args: PackedStringArray = []
var _heartbeat: float = 0.0

# Estado del generador de capturas (make_screenshots).
var _shot_idx: int = 0
var _shot_count: int = 8
var _shot_prefix: String = "phone"

func _ready() -> void:
	_args = OS.get_cmdline_user_args()
	GameManager.game_over.connect(_on_game_over)
	call_deferred("_run")

func _run() -> void:
	if "autostart" in _args:
		main.start_game()
	if "test_gameover" in _args:
		await _test_gameover()
	if "test_save" in _args:
		await _test_save()
	if "test_pause" in _args:
		await _test_pause()
	if "test_screenshot" in _args:
		await _test_screenshot()
	if "test_damage" in _args:
		await _test_damage()
	if "test_boss" in _args:
		await _test_boss()
	if "test_minions" in _args:
		await _test_minions()
	if "test_cycles" in _args:
		await _test_cycles()
	if "test_enemies" in _args:
		await _test_enemies()
	if "test_powerups" in _args:
		await _test_powerups()
	if "test_audio" in _args:
		await _test_audio()
	if "test_difficulty" in _args:
		await _test_difficulty()
	if "render_music" in _args:
		await _test_render_music()
	if "make_screenshots" in _args:
		await _make_screenshots()

func _process(delta: float) -> void:
	_heartbeat += delta
	if _heartbeat < 1.0:
		return
	_heartbeat = 0.0
	var s: Dictionary = main.debug_snapshot()
	print("[TEST] t=%s wave=%d cycle=%d alive=%d enemies=%d score=%d lives=%d bullets=%d boss=%s" % [
		"%.1f" % s["elapsed"], s["wave"], s["cycle"], s["alive"], s["enemies"],
		s["score"], s["lives"], s["bullets"], s["boss"]
	])

func _on_game_over() -> void:
	print("[TEST] GAME OVER score=%d lives=%d" % [GameManager.score, GameManager.lives])

# ---------------------------------------------------------------------------
# Casos de prueba
# ---------------------------------------------------------------------------
func _test_gameover() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("[TEST] lives before=%d running=%s" % [GameManager.lives, GameManager.game_running])
	GameManager.lives = 1
	main.player.take_damage(1)
	await get_tree().process_frame
	await get_tree().process_frame
	print("[TEST] after lethal hit: state=%d (espera %d=GAMEOVER) lives=%d" % [
		main.state, Main.State.GAMEOVER, GameManager.lives
	])
	var can_restart: bool = main.state == Main.State.GAMEOVER
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	main._unhandled_input(ev)
	await get_tree().process_frame
	print("[TEST] tras confirmar: state=%d (espera %d=START) restart_ok=%s" % [
		main.state, Main.State.START, can_restart and main.state == Main.State.START
	])
	get_tree().quit()

func _test_save() -> void:
	await get_tree().process_frame
	# El récord real del jugador puede superar 1234 y save_high_score() sólo
	# guarda si iguala o mejora el récord: por eso se respeta el original, se
	# fuerza un cero temporal y se restaura todo al final.
	var original: int = SaveManager.get_high_score()
	SaveManager._cache["high_score"] = 0
	SaveManager.save_high_score(1234)
	SaveManager.load_data()  # releer del disco (prueba real de persistencia)
	var read_back := SaveManager.get_high_score()
	GameManager.load_high_score()
	var save_ok: bool = (read_back == 1234 and GameManager.high_score == 1234)
	print("[TEST] save roundtrip: escrito=1234 leido=%d gamemanager=%d igual=%s save_ok=%s" % [
		read_back, GameManager.high_score, read_back == 1234 and GameManager.high_score == 1234, save_ok
	])
	SaveManager._cache["high_score"] = original
	SaveManager.save_high_score(original)
	GameManager.load_high_score()
	print("[TEST] save restaurado a récord original -> %d" % SaveManager.get_high_score())
	get_tree().quit()

func _test_pause() -> void:
	for i in 30:
		await get_tree().process_frame
	var enemies: Node2D = main.enemies_root
	var enemy: Node2D = enemies.get_child(0) if enemies.get_child_count() > 0 else null
	print("[TEST] pause: enemigos=%d paused=%s" % [enemies.get_child_count(), get_tree().paused])
	var y_before: float = enemy.position.y if enemy else 0.0
	main.toggle_pause()
	await get_tree().process_frame
	var paused_after := get_tree().paused
	for i in 10:
		await get_tree().process_frame
	var y_paused: float = enemy.position.y if enemy else 0.0
	var frozen := is_equal_approx(y_before, y_paused)
	main.toggle_pause()
	for i in 10:
		await get_tree().process_frame
	var y_after: float = enemy.position.y if enemy else 0.0
	print("[TEST] pause: paused=%s congelado=%s movio_al_reanudar=%s" % [
		paused_after, frozen, y_after > y_paused
	])
	get_tree().quit()

func _test_screenshot() -> void:
	var elapsed := 0.0
	while elapsed < 3.0 and is_inside_tree():
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "res://tests/screenshot.png"
	var err := img.save_png(path)
	print("[TEST] screenshot -> %s (err=%d, %dx%d)" % [path, err, img.get_width(), img.get_height()])
	get_tree().quit()

func _test_damage() -> void:
	await get_tree().process_frame
	var weaver: Node2D = load("res://scenes/enemies/enemy_weaver.tscn").instantiate()
	var grunt: Node2D = load("res://scenes/enemies/enemy_grunt.tscn").instantiate()
	main.enemies_root.add_child(weaver)
	main.enemies_root.add_child(grunt)
	await get_tree().process_frame

	var weaver_hp: int = weaver.health
	var weaver_interval: float = weaver.shoot_interval
	var weaver_timer_wait: float = weaver.shoot_timer.wait_time
	var grunt_interval: float = grunt.shoot_interval
	var grunt_timer_wait: float = grunt.shoot_timer.wait_time

	# Comprobar que ambos tipos se desplazan horizontalmente (se "mueven"),
	# antes de destruirlos.
	var weaver_moves: bool = await _moves_horizontally(weaver)
	var grunt_moves: bool = await _moves_horizontally(grunt)

	var score0: int = GameManager.score
	# Balance actual: weaver y grunt tienen 2 de vida; resisten un impacto
	# (queda en 1) y mueren al segundo. Recompensas: 30 y 20 puntos.
	weaver.take_damage(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var weaver_resists: bool = is_instance_valid(weaver) and weaver.health == 1
	weaver.take_damage(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var weaver_dead: bool = not is_instance_valid(weaver)
	var weaver_delta: int = GameManager.score - score0

	var grunt_hp: int = grunt.health
	var grunt_score0: int = GameManager.score
	grunt.take_damage(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var grunt_resists: bool = is_instance_valid(grunt) and grunt.health == 1
	if is_instance_valid(grunt):
		grunt.take_damage(1)
		await get_tree().process_frame
		await get_tree().process_frame
	var grunt_dead: bool = not is_instance_valid(grunt)
	var grunt_delta: int = GameManager.score - grunt_score0

	print("[TEST] weaver: hp=%d resiste_1=%s muere_de_2=%s puntos=%d (espera hp=2, true, true, 30)" % [
		weaver_hp, weaver_resists, weaver_dead, weaver_delta
	])
	print("[TEST] grunt: hp=%d resiste_1=%s muere_de_2=%s puntos=%d (espera hp=2, true, true, 20)" % [
		grunt_hp, grunt_resists, grunt_dead, grunt_delta
	])
	print("[TEST] movimiento: weaver=%s grunt=%s (espera true y true)" % [
		weaver_moves, grunt_moves
	])
	# Cadencia enemiga reducida: ambos disparan como mínimo cada 3 s y el Timer
	# del nodo coincide con el intervalo exportado.
	var weaver_timer_ok: bool = is_equal_approx(weaver_timer_wait, weaver_interval)
	var grunt_timer_ok: bool = is_equal_approx(grunt_timer_wait, grunt_interval)
	var cadence_ok: bool = weaver_interval >= 3.0 and grunt_interval >= 3.0 and weaver_timer_ok and grunt_timer_ok
	print("[TEST] intervalo_disparo: weaver=%s grunt=%s timers_ok=%s cadencia_reducida=%s" % [
		weaver_interval, grunt_interval, weaver_timer_ok and grunt_timer_ok, cadence_ok
	])
	get_tree().quit()

## Devuelve true si el enemigo cambia su coordenada X a lo largo del tiempo.
func _moves_horizontally(enemy: Node2D) -> bool:
	var x0: float = enemy.position.x
	for i in 20:
		await get_tree().process_frame
		if absf(enemy.position.x - x0) > 1.0:
			return true
	return false

## Verifica que el jefe aparece tras la última oleada del ciclo, tiene barra de
## vida y que, al destruirlo, sube la dificultad (ciclo+1) y la partida sigue.
func _test_boss() -> void:
	await get_tree().process_frame
	main.start_game()
	await get_tree().process_frame

	# Simular que se completaron las 10 oleadas del ciclo.
	main._wave_in_cycle = Main.WAVES_PER_CYCLE - 1
	main._boss_spawned = false
	main._after_boss = false
	main._pending.clear()
	main._alive = 0
	main._intermission = 0.0
	for i in 5:
		await get_tree().process_frame

	var boss: Node = main._boss
	var boss_ok: bool = boss != null and is_instance_valid(boss)
	var bar_visible: bool = main.hud.boss_bar.visible
	var hp: int = boss.health if boss_ok else 0
	print("[TEST] jefe tras %d oleadas: existe=%s barra_visible=%s hp=%d" % [
		Main.WAVES_PER_CYCLE, boss_ok, bar_visible, hp
	])

	if boss_ok:
		var cycle_before: int = main._cycle
		boss.take_damage(hp)
		await get_tree().process_frame
		await get_tree().process_frame
		var cycle_up: bool = main._cycle == cycle_before + 1
		var still_playing: bool = main.state == Main.State.PLAYING
		print("[TEST] jefe destruido: ciclo %d->%d (espera +1) sigue_jugando=%s (espera true)" % [
			cycle_before, main._cycle, still_playing
		])
		print("[TEST] dificultad sube: %s" % cycle_up)
		# Tras la pausa debe arrancar la oleada 0 del ciclo nuevo.
		main._intermission = 0.0
		for i in 3:
			await get_tree().process_frame
		var restarted: bool = main._wave_in_cycle == 0 and not main._after_boss and not main._pending.is_empty()
		print("[TEST] ciclo nuevo arranca en oleada 0: %s (espera true)" % restarted)
	else:
		print("[TEST] jefe NO apareció (fallo)")
	get_tree().quit()

## Verifica que el jefe lanza "navecitas" y que éstas mueren de un solo impacto.
func _test_minions() -> void:
	await get_tree().process_frame
	main.start_game()
	await get_tree().process_frame
	main._wave_in_cycle = Main.WAVES_PER_CYCLE - 1
	main._boss_spawned = false
	main._pending.clear()
	main._alive = 0
	main._intermission = 0.0
	for i in 5:
		await get_tree().process_frame

	var boss: Node = main._boss
	var boss_ok: bool = boss != null and is_instance_valid(boss)
	var timer_active: bool = boss_ok and not boss.minion_timer.is_stopped()
	var before: int = _count_minions()
	if boss_ok:
		boss._spawn_minions()  # forzar un enjambre
	await get_tree().process_frame
	await get_tree().process_frame
	var after: int = _count_minions()
	print("[TEST] navecitas: jefe=%s timer_activo=%s antes=%d despues=%d (espera jefe=true, timer=true, despues>antes)" % [
		boss_ok, timer_active, before, after
	])

	var minion: Node = _first_minion()
	if minion:
		# Debe disparar apuntando al jugador (que está más abajo). La bala se
		# captura justo después de llamar (el spawn es síncrono): así no la pisa
		# el disparo automático del jugador en el frame siguiente.
		var bullets_before: int = main.bullets_root.get_child_count()
		minion._on_shoot_timeout()
		var count_now: int = main.bullets_root.get_child_count()
		var fired: bool = count_now > bullets_before
		var aimed_down := false
		if fired:
			var b: Node = main.bullets_root.get_child(count_now - 1)
			aimed_down = b.direction.y > 0.0
		print("[TEST] navecita dispara: %s apunta_al_jugador=%s (espera true y true)" % [fired, aimed_down])

		var hp: int = minion.health
		var score0: int = GameManager.score
		minion.take_damage(1)
		await get_tree().process_frame
		await get_tree().process_frame
		var dead: bool = not is_instance_valid(minion)
		print("[TEST] navecita hp=%d muere_de_1=%s puntos=%d (espera hp=1, true, 15)" % [
			hp, dead, GameManager.score - score0
		])
	else:
		print("[TEST] navecita NO se creó (fallo)")
	get_tree().quit()

func _count_minions() -> int:
	var n := 0
	for c in main.enemies_root.get_children():
		if c is EnemyMinion:
			n += 1
	return n

func _first_minion() -> Node:
	for c in main.enemies_root.get_children():
		if c is EnemyMinion:
			return c
	return null

## Verifica el ciclo: sin jefe antes de las 10 oleadas, jefe al completarlas,
## dificultad creciente y navecitas centradas (no pegadas al borde).
func _test_cycles() -> void:
	await get_tree().process_frame
	main.start_game()
	await get_tree().process_frame
	var no_boss_early: bool = main._boss == null

	# Dificultad: un enemigo del ciclo 3 / oleada 10 es más rápido que uno del 0/0.
	var grunt_scene: PackedScene = load("res://scenes/enemies/enemy_grunt.tscn")
	main._cycle = 0
	main._wave_in_cycle = 0
	main._spawn_enemy({"scene": grunt_scene, "x": 100.0, "t": 0.0})
	var e0: Node = main.enemies_root.get_child(main.enemies_root.get_child_count() - 1)
	main._cycle = 3
	main._wave_in_cycle = Main.WAVES_PER_CYCLE - 1
	main._spawn_enemy({"scene": grunt_scene, "x": 260.0, "t": 0.0})
	var e1: Node = main.enemies_root.get_child(main.enemies_root.get_child_count() - 1)
	await get_tree().process_frame
	var harder: bool = e1.speed > e0.speed

	# Jefe tras completar el ciclo.
	main._cycle = 0
	main._wave_in_cycle = Main.WAVES_PER_CYCLE - 1
	main._boss_spawned = false
	main._after_boss = false
	main._pending.clear()
	main._alive = 0
	main._intermission = 0.0
	for i in 5:
		await get_tree().process_frame
	var boss: Node = main._boss
	var boss_ok: bool = boss != null and is_instance_valid(boss)

	# Navecitas centradas (regresión: antes se iban al borde izquierdo).
	var centered := false
	var minion_x := -1.0
	if boss_ok:
		boss._spawn_minions()
		await get_tree().process_frame
		await get_tree().process_frame
		var m: Node = _first_minion()
		if m:
			minion_x = m.position.x
			centered = minion_x > 40.0 and minion_x < 320.0

	print("[TEST] ciclos: sin_jefe_antes=%s jefe_tras_%d_oleadas=%s dificultad_sube=%s (%.1f<%.1f) navecita_x=%.1f centrada=%s" % [
		no_boss_early, Main.WAVES_PER_CYCLE, boss_ok, harder, e0.speed, e1.speed, minion_x, centered
	])
	get_tree().quit()

## Verifica los enemigos y formaciones nuevos: sprites, patrones por oleada,
## diver (kamikaze) y sniper (disparo apuntado).
func _test_enemies() -> void:
	await get_tree().process_frame
	main.start_game()
	await get_tree().process_frame

	# 1) Sprites nuevos generados por SpriteFactory.
	var ok_diver: bool = SpriteFactory.enemy_diver() != null
	var ok_sniper: bool = SpriteFactory.enemy_sniper() != null

	# 2) Cada oleada del ciclo produce specs válidos y no vacíos.
	var patterns_ok := true
	var total := 0
	for w in Main.WAVES_PER_CYCLE:
		main._wave_in_cycle = w
		main._cycle = 0
		var specs: Array = main._build_wave()
		if specs.is_empty():
			patterns_ok = false
		for s in specs:
			total += 1
			if not (s.has("scene") and s.has("x") and s.has("t")):
				patterns_ok = false

	# 3) Diver: muere de 1 impacto y desciende.
	var diver: Node2D = load("res://scenes/enemies/enemy_diver.tscn").instantiate()
	main.enemies_root.add_child(diver)
	diver.position = Vector2(120.0, 40.0)
	await get_tree().process_frame
	var diver_y0: float = diver.position.y
	for i in 20:
		await get_tree().process_frame
	var diver_moves: bool = diver.position.y > diver_y0
	var diver_hp: int = diver.health
	diver.take_damage(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var diver_dead: bool = not is_instance_valid(diver)

	# 4) Sniper: resiste 1 impacto (2 de vida) y muere al 2.º; dispara apuntando
	# al jugador (bala capturada de forma síncrona para no mezclarla con la del
	# jugador).
	var sniper: Node2D = load("res://scenes/enemies/enemy_sniper.tscn").instantiate()
	main.enemies_root.add_child(sniper)
	sniper.position = Vector2(240.0, 60.0)
	await get_tree().process_frame
	var sniper_hp: int = sniper.health
	var bullets_before: int = main.bullets_root.get_child_count()
	sniper._on_shoot_timeout()
	var sniper_count: int = main.bullets_root.get_child_count()
	var sniper_fired: bool = sniper_count > bullets_before
	var sniper_aimed := false
	if sniper_fired:
		var b: Node = main.bullets_root.get_child(sniper_count - 1)
		sniper_aimed = b.direction.y > 0.0
	sniper.take_damage(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var sniper_resists: bool = is_instance_valid(sniper) and sniper.health == 1
	if is_instance_valid(sniper):
		sniper.take_damage(1)
		await get_tree().process_frame
		await get_tree().process_frame
	var sniper_dead: bool = not is_instance_valid(sniper)

	print("[TEST] enemigos: sprites=%s/%s patrones_ok=%s specs=%d diver_hp=%d muere=%s se_mueve=%s sniper_hp=%d resiste_1=%s muere_de_2=%s dispara=%s apunta=%s" % [
		ok_diver, ok_sniper, patterns_ok, total, diver_hp, diver_dead, diver_moves,
		sniper_hp, sniper_resists, sniper_dead, sniper_fired, sniper_aimed
	])
	get_tree().quit()

## Verifica las mejoras: arma (más balas), escudo (absorbe 1 golpe), bomba
## (limpia balas enemigas y daña enemigos) y recogida por colisión.
func _test_powerups() -> void:
	await get_tree().process_frame
	main.start_game()
	await get_tree().process_frame
	main.player.shoot_timer.stop()  # evita el auto-disparo durante el conteo

	# A) Mejora de arma: nivel 1 -> 1 bala, nivel 3 -> 3 balas.
	GameManager.weapon_level = 1
	for b in main.bullets_root.get_children():
		b.queue_free()
	await get_tree().process_frame
	main.player.shoot()
	await get_tree().process_frame
	var n1: int = _count_player_bullets()

	GameManager.upgrade_weapon()
	GameManager.upgrade_weapon()
	var weapon: int = GameManager.weapon_level
	for b in main.bullets_root.get_children():
		b.queue_free()
	await get_tree().process_frame
	main.player.shoot()
	await get_tree().process_frame
	var n3: int = _count_player_bullets()

	# B) Escudo: absorbe un impacto (no pierde vida) y se consume.
	GameManager.weapon_level = 2
	GameManager.add_shield()
	var lives0: int = GameManager.lives
	main.player._invuln = 0.0
	main.player.take_damage(1)
	var lives_after_shield: int = GameManager.lives
	var shield_after: int = GameManager.shield
	# El segundo golpe (ya sin escudo) sí quita vida y reinicia el arma.
	main.player._invuln = 0.0
	main.player.take_damage(1)
	var lives_after_hit: int = GameManager.lives
	var weapon_after_death: int = GameManager.weapon_level

	# C) Bomba: consume carga, limpia balas enemigas y daña enemigos.
	GameManager.add_bomb()
	var eb: Area2D = load("res://scenes/projectiles/enemy_bullet.tscn").instantiate()
	main.bullets_root.add_child(eb)
	eb.global_position = Vector2(180, 200)
	var en: Node2D = load("res://scenes/enemies/enemy_grunt.tscn").instantiate()
	main.enemies_root.add_child(en)
	en.position = Vector2(180, 120)
	await get_tree().process_frame
	var bombs0: int = GameManager.bombs
	main._use_bomb()
	await get_tree().process_frame
	await get_tree().process_frame
	var bombs1: int = GameManager.bombs
	var enemy_dead: bool = not is_instance_valid(en)
	var enemy_bullets_left := 0
	for b in main.bullets_root.get_children():
		if b is EnemyBullet:
			enemy_bullets_left += 1
	# Sin cargas no debe hacer nada.
	GameManager.bombs = 0
	var before_nobomb: int = main.bullets_root.get_child_count()
	main._use_bomb()
	var no_bomb_ok: bool = GameManager.bombs == 0 and main.bullets_root.get_child_count() == before_nobomb

	# D) Recogida por colisión: un power-up tocado por el jugador aplica su efecto.
	var bombs_before: int = GameManager.bombs
	var pu: Area2D = load("res://scenes/items/powerup.tscn").instantiate()
	pu.kind = PowerUp.Kind.BOMB
	main.items_root.add_child(pu)
	pu.global_position = main.player.global_position
	for i in 6:
		await get_tree().physics_frame
	var pickup_ok: bool = GameManager.bombs == bombs_before + 1
	var pu_gone: bool = not is_instance_valid(pu)

	print("[TEST] mejoras: balas_n1=%d balas_n3=%d arma=%d escudo_absorbe=%s (vidas %d->%d) escudo_consumido=%d golpe_sin_escudo=%s (vidas=%d) arma_reset=%d bomba_usa=%s enemigo_muere=%s balas_enemigas=%d sin_carga_ok=%s recogida=%s objeto_consumido=%s" % [
		n1, n3, weapon, lives_after_shield == lives0, lives0, lives_after_shield, shield_after,
		lives_after_hit == lives0 - 1, lives_after_hit, weapon_after_death,
		bombs1 == bombs0 - 1, enemy_dead, enemy_bullets_left, no_bomb_ok, pickup_ok, pu_gone
	])
	get_tree().quit()

func _count_player_bullets() -> int:
	var n := 0
	for b in main.bullets_root.get_children():
		if b is PlayerBullet:
			n += 1
	return n

## Verifica el AudioManager: efectos sintetizados, música en bucle y silencio.
func _test_audio() -> void:
	await get_tree().process_frame

	var names := ["shoot", "explosion", "hit", "powerup", "bomb", "boss_hit", "angel"]
	var streams_ok := true
	for n in names:
		var s: AudioStreamWAV = AudioManager._streams.get(n, null)
		if s == null or s.data.size() == 0:
			streams_ok = false

	var music: AudioStream = AudioManager._music
	var music_ok: bool = music != null and _music_usable(music)

	# Reproducir no debe fallar (aunque headless use un driver dummy).
	AudioManager.play_sfx("shoot")
	AudioManager.play_sfx("explosion")
	AudioManager.play_music()
	await get_tree().process_frame

	# Silenciar detiene la música.
	AudioManager.set_muted(true)
	var mute_ok: bool = AudioManager.muted and not AudioManager._music_player.playing
	AudioManager.set_muted(false)

	print("[TEST] audio: streams_ok=%s music_ok=%s bytes_shoot=%d bytes_music=%s mute_ok=%s" % [
		streams_ok, music_ok, (AudioManager._streams["shoot"] as AudioStreamWAV).data.size(),
		_music_sample_count(music), mute_ok
	])
	get_tree().quit()

## Un stream de música es "usable" si existe y, para WAV, tiene samples/loop.
func _music_usable(music: AudioStream) -> bool:
	if music == null:
		return false
	if music is AudioStreamWAV:
		var wav: AudioStreamWAV = music
		if wav.data != null and wav.data.size() > 0 \
			and wav.loop_mode == AudioStreamWAV.LOOP_FORWARD:
			return true
		return music.get_length() > 0.0
	return music.get_length() > 0.0

func _music_sample_count(music: AudioStream) -> int:
	if music is AudioStreamWAV:
		var wav: AudioStreamWAV = music
		return wav.data.size() if wav.data != null else 0
	return 0

## Herramienta de desarrollo: renderiza la música a WAV (assets/audio/*.wav)
## para no sintetizarla en el dispositivo. Uso:
##   godot --headless --path . -- render_music
func _test_render_music() -> void:
	await get_tree().process_frame
	AudioManager.render_music_files()
	get_tree().quit()

# ---------------------------------------------------------------------------
# Generador de capturas para la ficha de Google Play
# ---------------------------------------------------------------------------
## Genera las capturas exigidas por Play Console (8 de celular, 2 de tablet,
## 2 de reloj) renderizando con VENTANA REAL (no sirve en headless). Uso:
##   godot --path <proyecto> -- make_screenshots
## Salida: build/screenshots/<dispositivo>_NN_<momento>.png
func _make_screenshots() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	# [ancho, alto, cantidad de tomas, prefijo]
	var jobs := [
		[1080, 1920, 8, "phone"],
		[1600, 2560, 2, "tablet"],
		[450, 450, 2, "watch"],
	]
	for job in jobs:
		DisplayServer.window_set_size(Vector2i(int(job[0]), int(job[1])))
		await _wait_frames(5)
		await _shots_cycle(int(job[2]), String(job[3]))
	get_tree().quit()

func _shots_cycle(count: int, prefix: String) -> void:
	_shot_idx = 0
	_shot_count = count
	_shot_prefix = prefix

	# 1) Menú de inicio.
	main.enter_start()
	GameManager.score = 0
	await _wait_frames(30)
	await _maybe_shot("menu")

	# 2) Partida en curso: oleadas de enemigos y puntuación en el HUD.
	main.start_game()
	GameManager.add_score(12450)
	await _wait_frames(240)
	await _maybe_shot("juego")

	# 3) Mejoras a la vista: arma nivel 3, escudo, bomba, power-up a la deriva
	#    y racha de combo.
	GameManager.upgrade_weapon()
	GameManager.upgrade_weapon()
	GameManager.add_shield()
	GameManager.add_bomb()
	var pu: Area2D = load("res://scenes/items/powerup.tscn").instantiate()
	pu.kind = PowerUp.Kind.WEAPON
	main.items_root.add_child(pu)
	pu.global_position = Vector2(180.0, 300.0)
	main._combo = 4
	main.hud.show_combo(4)
	await _wait_frames(10)
	await _maybe_shot("mejoras")

	# 4-6) Jefe: aviso, pelea con barra de vida y lanzamiento de navecitas.
	if _shot_idx < _shot_count:
		# Vaciar la oleada de verdad (sin trucar `_alive`: si queda descuadrado,
		# el juego cree que la oleada terminó y lanza un segundo jefe).
		main._wave_in_cycle = Main.WAVES_PER_CYCLE - 1
		main._clear_enemies()
		main._pending.clear()
		main._intermission = 0.0
		for i in 600:
			await get_tree().process_frame
			if is_instance_valid(main._boss):
				break
		await _wait_frames(15)
		await _maybe_shot("aviso_jefe")
		# Vida de sobra: el jefe tiene que sobrevivir toda la sesión de fotos
		# (si no, el jugador lo mata solo y se pierden las tomas de la pelea).
		if is_instance_valid(main._boss):
			main._boss.health = 400
			main._boss._max_health = 400
			main.hud.show_boss(400)
		await _wait_frames(160)
		await _maybe_shot("jefe")
		if is_instance_valid(main._boss):
			main._boss._spawn_minions()
		await _wait_frames(90)
		await _maybe_shot("navecitas")

	# 7) Alma liberada del primer jefe: el ángel entre estrellitas y corazones.
	if _shot_idx < _shot_count:
		if is_instance_valid(main._boss):
			main._boss.take_damage(9999)
		# Esperar a que pase el cartel "NIVEL 2" (2 s) para que la escena no
		# salga oscurecida por el telón; el alma dura 6,5 s.
		await _wait_frames(150)
		await _maybe_shot("angel")

	# 8) Game over.
	GameManager.shield = 0
	main.player._invuln = 0.0
	GameManager.lives = 1
	main.player.take_damage(1)
	await _wait_frames(30)
	await _maybe_shot("gameover")

## Toma una captura si aún no se completó la cantidad pedida para este tamaño.
func _maybe_shot(momento: String) -> void:
	_shot_idx += 1
	if _shot_idx > _shot_count:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var fname := "res://build/screenshots/%s_%02d_%s.png" % [_shot_prefix, _shot_idx, momento]
	var err := img.save_png(fname)
	print("[SHOTS] %s -> %dx%d err=%d estado=%d ciclo=%d jefe=%s jefe_vida=%d overlay=%s aviso=%s" % [
		fname, img.get_width(), img.get_height(), err,
		main.state, main._cycle,
		is_instance_valid(main._boss),
		(main._boss.health if is_instance_valid(main._boss) else -1),
		main.hud.center_panel.visible,
		main.hud.message_label.visible,
	])

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

## Verifica la pantalla de inicio y la selección de dificultad.
func _test_difficulty() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	# Al arrancar debe verse el menú (no una partida en curso).
	var panel_ok: bool = main.hud.start_panel.visible and main.state == Main.State.START

	# El logo tipográfico debe estar cargado y visible.
	var logo: TextureRect = main.hud.start_panel.get_node_or_null("TitleLogo")
	var logo_ok: bool = logo != null and logo.texture != null \
		and logo.texture.get_width() >= 300 and logo.visible

	# Elegir DIFÍCIL desde el menú (equivale a tocar/confirmar la opción).
	main.hud._on_difficulty_clicked(GameManager.Difficulty.HARD)
	await get_tree().process_frame
	await get_tree().process_frame

	var hard_ok: bool = GameManager.difficulty == GameManager.Difficulty.HARD
	var lives_ok: bool = GameManager.lives == 2
	var speed_ok: bool = GameManager.enemy_speed_mult() > 1.0
	var hp_ok: bool = GameManager.enemy_hp_bonus() == 1
	var drop_ok: bool = GameManager.drop_chance_mult() < 1.0
	var playing_ok: bool = main.state == Main.State.PLAYING and not main.hud.start_panel.visible

	# Puntaje x1.5 en difícil.
	GameManager.score = 0
	GameManager.add_score(10)
	var score_ok: bool = GameManager.score == 15

	# NORMAL restaura los valores clásicos.
	GameManager.set_difficulty(GameManager.Difficulty.NORMAL)
	var normal_ok: bool = GameManager.start_lives() == 3 \
		and is_equal_approx(GameManager.enemy_speed_mult(), 1.0) \
		and GameManager.enemy_hp_bonus() == 0 \
		and is_equal_approx(GameManager.score_mult(), 1.0)

	print("[TEST] dificultad: menu=%s logo=%s dificil=%s vidas2=%s mas_rapidos=%s hp_extra=%s menos_drops=%s jugando=%s puntaje_x1.5=%s normal=%s" % [
		panel_ok, logo_ok, hard_ok, lives_ok, speed_ok, hp_ok, drop_ok, playing_ok, score_ok, normal_ok
	])
	get_tree().quit()
