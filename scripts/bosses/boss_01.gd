extends EnemyBase
class_name Boss01

## Jefe 01 — "JUAMPI EVIL".
##
## Primer jefe de cada ciclo: aparece tras superar la última oleada, desciende
## desde arriba, se detiene a cierta altura y patrulla en horizontal mientras
## dispara abanicos de proyectiles.
##
## Al ser destruido no termina la partida: el maleficio se rompe y aparece su
## forma liberada (el ángel "JUAMPI" bueno) flotando entre estrellitas y
## corazoncitos, con un mensaje de agradecimiento titilante. Después el ciclo
## sube y la invasión continúa.
##
## El sprite se toma de assets/sprites/bosses/boss_juampi_evil.png. Si el
## archivo no existe, cae a un sprite provisional generado por código.
##
## Frase de entrada: "AVERIGUEMOS CUAL ES TU PERFIL / ESTOY SEGURO QUE SOS
## PURO HUMO!!!".

signal health_changed(current: int, maximum: int)

const TEXTURE_PATH := "res://assets/sprites/bosses/boss_juampi_evil.png"
const MINION := preload("res://scenes/enemies/enemy_minion.tscn")

## Nombre que muestra el aviso de advertencia.
@export var boss_name: String = "JUAMPI EVIL"

## Frase que aparece titilando al entrar el jefe (vacía = no mostrar nada).
@export var intro_message: String = "AVERIGUEMOS CUAL ES TU PERFIL\nESTOY SEGURO QUE SOS PURO HUMO!!!"

## Forma liberada: al morir, este sprite aparece en su lugar con estrellitas y
## corazoncitos. Vacío = el jefe simplemente explota.
@export var soul_texture_path: String = "res://assets/sprites/bosses/boss_juampi_angel.png"
## Mensaje que deja el alma liberada (titila unos segundos sobre la partida).
@export var soul_message: String = "¡GRACIAS! ¡GRACIAS! ♥\nROMPISTE EL MALEFICIO\nQUE ME TENÍA POSEÍDO"

@export var hover_y: float = 150.0       # altura donde se detiene y patrulla
@export var amplitude: float = 88.0      # recorrido horizontal
@export var frequency: float = 1.1       # velocidad del vaivén
@export var fan_bullets: int = 5         # proyectiles por ráfaga
@export var fan_spread_deg: float = 46.0 # apertura total del abanico
@export var minion_interval: float = 4.0 # cada cuánto lanza "navecitas"
@export var minions_per_spawn: int = 2   # cuántas lanza por vez
@export var minion_speed_bonus: float = 0.0  # velocidad extra por dificultad

var _origin_x: float = 0.0
var _entered: bool = false
var _max_health: int = 1

@onready var minion_timer: Timer = $MinionTimer

func _sprite_texture() -> Texture2D:
	if ResourceLoader.exists(TEXTURE_PATH):
		var tex := load(TEXTURE_PATH)
		if tex is Texture2D:
			return tex
	return SpriteFactory.enemy_weaver()  # respaldo provisional

func _ready() -> void:
	super._ready()
	_origin_x = position.x
	_max_health = maxi(health, 1)
	health_changed.emit(health, _max_health)
	if has_node("MinionTimer"):
		minion_timer.wait_time = minion_interval
		minion_timer.timeout.connect(_on_minion_timeout)
		minion_timer.start()

func _move(delta: float) -> void:
	_time += delta
	if not _entered:
		# Entrada: baja hasta la altura de patrulla.
		position.y += speed * delta
		if position.y >= hover_y:
			position.y = hover_y
			_entered = true
			_origin_x = position.x
		return
	# Patrulla horizontal con leve balanceo vertical. Nunca baja del área.
	position.x = _origin_x + sin(_time * frequency) * amplitude
	position.y = hover_y + sin(_time * 0.7) * 6.0

func _on_shoot_timeout() -> void:
	if not GameManager.game_running:
		return
	_fire_fan()

func _fire_fan() -> void:
	var count := maxi(fan_bullets, 1)
	var spread := deg_to_rad(fan_spread_deg)
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		var angle := (PI * 0.5) + t * spread  # abanico hacia abajo
		_spawn_bullet_dir(Vector2.RIGHT.rotated(angle))

func _on_minion_timeout() -> void:
	if not GameManager.game_running:
		return
	_spawn_minions()

## Lanza un pequeño enjambre de "navecitas" que descienden hacia el jugador.
func _spawn_minions() -> void:
	var count := maxi(minions_per_spawn, 1)
	var layer := get_tree().get_first_node_in_group("enemy_layer")
	if layer == null:
		layer = get_parent()
	if layer == null:
		return
	for i in count:
		var minion: Area2D = MINION.instantiate()
		minion.speed += minion_speed_bonus
		layer.add_child(minion)
		var offset_x := (float(i) - (float(count) - 1.0) * 0.5) * 34.0
		minion.global_position = global_position + Vector2(offset_x, 44.0)
		# Re-sincronizar el origen del zigzag con la posición real (la posición
		# se asigna después de add_child, cuando ya corrió _ready).
		if minion.has_method("reset_origin"):
			minion.reset_origin()

## El jefe NO muere al chocar con el jugador: sólo le hace daño.
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(1)

func take_damage(damage: int) -> void:
	if health > 0:
		AudioManager.play_sfx("boss_hit")
	super.take_damage(damage)
	health_changed.emit(maxi(health, 0), _max_health)
