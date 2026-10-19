extends EnemyBase
class_name BossColin

## Jefe — "BOSS COLIN" (boss_colin.png).
##
## Cuarto de la rotación: aparece justo después de Farol Faina (ciclo % 6 == 3).
## Al entrar titila: "VAMOS A AVERIGUAR TU PERFIIILLLLLL!!".

signal health_changed(current: int, maximum: int)

const TEXTURE_PATH := "res://assets/sprites/bosses/boss_colin.png"
const MINION := preload("res://scenes/enemies/enemy_minion.tscn")

@export var boss_name: String = "BOSS COLIN"
@export var intro_message: String = "VAMOS A AVERIGUAR TU PERFIIILLLLLL!!"
@export var soul_texture_path: String = ""
@export var soul_message: String = ""

@export var hover_y: float = 150.0
@export var amplitude: float = 88.0
@export var frequency: float = 1.1
@export var fan_bullets: int = 5
@export var fan_spread_deg: float = 46.0
@export var minion_interval: float = 3.6
@export var minions_per_spawn: int = 2
@export var minion_speed_bonus: float = 0.0

var _origin_x: float = 0.0
var _entered: bool = false
var _max_health: int = 1

@onready var minion_timer: Timer = $MinionTimer

func _sprite_texture() -> Texture2D:
	if ResourceLoader.exists(TEXTURE_PATH):
		var tex := load(TEXTURE_PATH)
		if tex is Texture2D:
			return tex
	return SpriteFactory.enemy_weaver()

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
		position.y += speed * delta
		if position.y >= hover_y:
			position.y = hover_y
			_entered = true
			_origin_x = position.x
		return
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
		var angle := (PI * 0.5) + t * spread
		_spawn_bullet_dir(Vector2.RIGHT.rotated(angle))

func _on_minion_timeout() -> void:
	if not GameManager.game_running:
		return
	_spawn_minions()

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
		if minion.has_method("reset_origin"):
			minion.reset_origin()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(1)

func take_damage(damage: int) -> void:
	if health > 0:
		AudioManager.play_sfx("boss_hit")
	super.take_damage(damage)
	health_changed.emit(maxi(health, 0), _max_health)
