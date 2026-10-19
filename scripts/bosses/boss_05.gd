extends EnemyBase
class_name Boss05

## Jefe 05 — "EL INFE"
signal health_changed(current: int, maximum: int)

const TEXTURE_PATH := "res://assets/sprites/bosses/boss_infe.png"
const MINION := preload("res://scenes/enemies/enemy_minion.tscn")

@export var boss_name: String = "EL INFE"
@export var intro_message: String = "DONDE ESTA MI PERNUANITA , DONDE ?"
@export var soul_texture_path: String = ""
@export var soul_message: String = "DONDE ESTA MI PERNUANITA , DONDE ?"

@export var hover_y: float = 140.0
@export var amplitude: float = 110.0
@export var frequency: float = 0.9
@export var volley_count: int = 3
@export var bullets_per_volley: int = 4
@export var spread_deg: float = 60.0
@export var volley_interval: float = 1.2
@export var minion_interval: float = 3.0
@export var minions_per_spawn: int = 3
@export var minion_speed_bonus: float = 20.0
@export var burst_pause: float = 0.25

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
	position.y = hover_y + cos(_time * 0.9) * 10.0

func _on_shoot_timeout() -> void:
	if not GameManager.game_running:
		return
	_fire_volley()

func _fire_volley() -> void:
	var v := maxi(volley_count, 1)
	for i in v:
		var count := maxi(bullets_per_volley, 1)
		var spread := deg_to_rad(spread_deg)
		for j in count:
			var t := 0.0 if count == 1 else float(j) / float(count - 1) - 0.5
			var angle := (PI * 0.5) + t * spread
			_spawn_bullet_dir(Vector2.RIGHT.rotated(angle))
		if i < v - 1:
			await get_tree().create_timer(burst_pause).timeout

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
		var offset_x := (float(i) - (float(count) - 1.0) * 0.5) * 28.0
		minion.global_position = global_position + Vector2(offset_x, 52.0)
		if minion.has_method("reset_origin"):
			minion.reset_origin()
		if minion.has_node("ShootTimer"):
			var st := minion.get_node("ShootTimer") as Timer
			if st != null:
				st.wait_time = maxf(1.4, st.wait_time * 0.8)
				st.start()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(1)

func take_damage(damage: int) -> void:
	if health > 0:
		AudioManager.play_sfx("boss_hit")
	super.take_damage(damage)
	health_changed.emit(maxi(health, 0), _max_health)
