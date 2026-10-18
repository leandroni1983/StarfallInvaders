extends EnemyBase
class_name EnemyType1

## "Grunt" enemy: descends while weaving gently from side to side and fires a
## single shot. Muere de un solo impacto.

@export var amplitude: float = 22.0
@export var frequency: float = 3.2

var _origin_x: float = 0.0

func _sprite_texture() -> Texture2D:
	return SpriteFactory.enemy_grunt()

func _ready() -> void:
	super._ready()
	_origin_x = position.x

func _move(delta: float) -> void:
	_time += delta
	position.y += speed * delta
	position.x = _origin_x + sin(_time * frequency) * amplitude
	if position.y > get_viewport_rect().size.y + 32.0:
		queue_free()
