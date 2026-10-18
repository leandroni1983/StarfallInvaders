extends CharacterBody2D
class_name Player

@export var speed: float = 280.0
@export var shoot_interval: float = 0.22
@export var touch_speed_factor: float = 1.0
@export var invulnerable_time: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shield_sprite: Sprite2D = $Shield
@onready var fire_point: Marker2D = $FirePoint
@onready var shoot_timer: Timer = $ShootTimer

const PLAYER_BULLET := preload("res://scenes/projectiles/player_bullet.tscn")

var _screen_rect: Rect2
var _is_dragging: bool = false
## Índice del dedo que está controlando la nave (multi-táctil: un segundo
## dedo tocando la pantalla no debe cancelar el arrastre en curso).
var _drag_finger: int = -1
var _invuln: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	_screen_rect = get_viewport_rect()
	if sprite:
		sprite.texture = SpriteFactory.player_ship()
	if shield_sprite:
		shield_sprite.texture = SpriteFactory.shield_ring()
	GameManager.shield_changed.connect(_on_shield_changed)
	_on_shield_changed(GameManager.shield)
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timeout)
	shoot_timer.start()

func _physics_process(delta: float) -> void:
	_t += delta
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6.0 * delta)
	move_and_slide()
	_clamp_to_screen()
	_update_invulnerability(delta)
	_update_shield(delta)

func _update_shield(_delta: float) -> void:
	if shield_sprite == null or not shield_sprite.visible:
		return
	shield_sprite.scale = Vector2.ONE * (2.5 + sin(_t * 5.0) * 0.15)

func _on_shield_changed(amount: int) -> void:
	if shield_sprite == null:
		return
	shield_sprite.visible = amount > 0

func _update_invulnerability(delta: float) -> void:
	if _invuln > 0.0:
		_invuln = maxf(0.0, _invuln - delta)
		# Parpadeo clásico de arcade.
		sprite.visible = int(_invuln * 14.0) % 2 == 0
		if _invuln == 0.0:
			sprite.visible = true
	else:
		sprite.visible = true

func reset() -> void:
	_invuln = 0.0
	velocity = Vector2.ZERO
	sprite.visible = true
	sprite.modulate = Color.WHITE
	_is_dragging = false
	_drag_finger = -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _drag_finger == -1:
			_drag_finger = event.index
			_is_dragging = true
		elif not event.pressed and event.index == _drag_finger:
			_drag_finger = -1
			_is_dragging = false
	elif event is InputEventScreenDrag:
		if _is_dragging and event.index == _drag_finger:
			position += event.relative * touch_speed_factor
			_clamp_to_screen()
	elif event is InputEventMouseButton:
		# Allow mouse drag for PC testing of touch controls
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
	elif event is InputEventMouseMotion and _is_dragging:
		position += event.relative * touch_speed_factor
		_clamp_to_screen()

func _clamp_to_screen() -> void:
	position.x = clampf(position.x, _screen_rect.position.x, _screen_rect.end.x)
	position.y = clampf(position.y, _screen_rect.position.y, _screen_rect.end.y)

func _on_shoot_timeout() -> void:
	shoot()

func shoot() -> void:
	if not GameManager.game_running or get_tree().paused:
		return
	# El nivel de arma abre el disparo: 1 bala -> 2 paralelas -> 3 en abanico.
	match GameManager.weapon_level:
		1:
			_fire(Vector2.UP, Vector2.ZERO)
		2:
			_fire(Vector2.UP, Vector2(-7, 0))
			_fire(Vector2.UP, Vector2(7, 0))
		_:
			_fire(Vector2.UP, Vector2.ZERO)
			_fire(Vector2.UP.rotated(-0.22), Vector2(-8, 2))
			_fire(Vector2.UP.rotated(0.22), Vector2(8, 2))
	AudioManager.play_sfx("shoot")

func _fire(dir: Vector2, offset: Vector2) -> void:
	var bullet: Area2D = PLAYER_BULLET.instantiate()
	bullet.direction = dir
	bullet.global_position = fire_point.global_position + offset
	_add_to_group_layer("bullet_layer", bullet)

func _add_to_group_layer(group: String, node: Node) -> void:
	var layer := get_tree().get_first_node_in_group(group)
	if layer:
		layer.add_child(node)
	else:
		get_parent().add_child(node)

func take_damage(_damage: int = 1) -> void:
	if not GameManager.game_running or _invuln > 0.0:
		return
	# El escudo absorbe el impacto antes que la vida.
	if GameManager.consume_shield():
		_invuln = invulnerable_time
		_flash_hurt()
		GameManager.request_shake(0.25)
		return
	GameManager.lose_life()
	_invuln = invulnerable_time
	_flash_hurt()
	GameManager.request_shake(0.6)
	AudioManager.play_sfx("hit")

func _flash_hurt() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
