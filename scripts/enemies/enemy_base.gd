extends Area2D
class_name EnemyBase

signal died(points: int)

@export var health: int = 2
@export var speed: float = 60.0
@export var points: int = 10
@export var shoot_interval: float = 2.0
@export var can_shoot: bool = true
@export var bullets_per_shot: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var fire_point: Marker2D = $FirePoint
@onready var shoot_timer: Timer = $ShootTimer

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
const EXPLOSION := preload("res://scenes/effects/explosion.tscn")

var _time: float = 0.0
var _dead: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.texture = _sprite_texture()
	if can_shoot and has_node("ShootTimer"):
		shoot_timer.wait_time = shoot_interval
		shoot_timer.timeout.connect(_on_shoot_timeout)
		shoot_timer.start()

## Overridable: subclasses return their own texture.
func _sprite_texture() -> Texture2D:
	return SpriteFactory.enemy_grunt()

func _process(delta: float) -> void:
	_move(delta)

func _move(delta: float) -> void:
	_time += delta
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 32.0:
		queue_free()

func _on_shoot_timeout() -> void:
	if not GameManager.game_running:
		return
	if bullets_per_shot <= 1:
		_spawn_bullet(Vector2.ZERO)
	else:
		var spread := 0.35
		for i in bullets_per_shot:
			var offset := (float(i) - (bullets_per_shot - 1) * 0.5)
			_spawn_bullet(Vector2(offset * 0.6, 0.0))

func _spawn_bullet(offset: Vector2) -> void:
	var bullet: Area2D = ENEMY_BULLET.instantiate()
	bullet.global_position = fire_point.global_position + offset
	var layer := get_tree().get_first_node_in_group("bullet_layer")
	if layer:
		layer.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)

## Dispara un proyectil en una dirección arbitraria (abanico del jefe, puntería
## de las navecitas, etc.).
func _spawn_bullet_dir(dir: Vector2) -> void:
	var bullet: Area2D = ENEMY_BULLET.instantiate()
	bullet.global_position = fire_point.global_position
	bullet.direction = dir
	var layer := get_tree().get_first_node_in_group("bullet_layer")
	if layer:
		layer.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)

func take_damage(damage: int) -> void:
	if _dead:
		return
	health -= damage
	if health <= 0:
		die()
	else:
		_flash_hurt()
		_spawn_sparks()

func _flash_hurt() -> void:
	if sprite == null:
		return
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

## Chispas breves al impactar sin destruir (feedback de "le hice daño").
func _spawn_sparks() -> void:
	var fx: Node2D = EXPLOSION.instantiate()
	fx.global_position = global_position
	fx.radius = 7.0
	fx.duration = 0.22
	fx.shard_count = 4
	fx.hue = Color("ffe08a")
	var layer := get_tree().get_first_node_in_group("effect_layer")
	if layer:
		layer.add_child(fx)
	else:
		get_tree().current_scene.add_child(fx)

func die() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_score(points)
	died.emit(points)
	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	var fx: Node2D = EXPLOSION.instantiate()
	fx.global_position = global_position
	var layer := get_tree().get_first_node_in_group("effect_layer")
	if layer:
		layer.add_child(fx)
	else:
		get_tree().current_scene.add_child(fx)
	AudioManager.play_sfx("explosion")

func _on_body_entered(body: Node2D) -> void:
	# Ram damage against the player.
	if body is Player:
		body.take_damage(1)
		die()
