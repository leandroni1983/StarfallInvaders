extends Area2D
class_name EnemyBullet

@export var speed: float = 240.0
@export var damage: int = 1
## Dirección de viaje. Por defecto hacia abajo (comportamiento original de los
## enemigos comunes); el jefe la reorienta para disparar en abanico.
@export var direction: Vector2 = Vector2.DOWN

var _dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_dir = direction.normalized()
	var s := get_node_or_null("Sprite2D") as Sprite2D
	if s:
		s.texture = SpriteFactory.bullet_enemy()

func _process(delta: float) -> void:
	position += _dir * speed * delta
	var view := get_viewport_rect().size
	if position.y > view.y + 32.0 or position.y < -48.0 or position.x < -48.0 or position.x > view.x + 48.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
