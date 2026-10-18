extends Area2D
class_name PlayerBullet

@export var speed: float = 520.0
@export var damage: int = 1
## Dirección de viaje. Por defecto hacia arriba; el arma mejorada puede
## desviarla ligeramente para abrir el disparo en abanico.
@export var direction: Vector2 = Vector2.UP

var _dir: Vector2 = Vector2.UP

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_dir = direction.normalized()
	var s := get_node_or_null("Sprite2D") as Sprite2D
	if s:
		s.texture = SpriteFactory.bullet_player()
		s.rotation = _dir.angle() + PI * 0.5

func _process(delta: float) -> void:
	position += _dir * speed * delta
	var view := get_viewport_rect().size
	if position.y < -32.0 or position.y > view.y + 32.0 or position.x < -32.0 or position.x > view.x + 32.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	queue_free()
