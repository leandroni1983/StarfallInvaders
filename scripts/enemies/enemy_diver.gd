extends EnemyBase
class_name EnemyDiver

## "Diver" (kamikaze): desciende acelerando y corrige su rumbo horizontal hacia la
## posición del jugador. No dispara; el peligro es la embestida. Muere de un
## solo impacto.

@export var homing_speed: float = 78.0  # px/s de corrección horizontal
@export var accel: float = 70.0         # aceleración vertical (hasta `speed`)

var _vy: float = 0.0

func _sprite_texture() -> Texture2D:
	return SpriteFactory.enemy_diver()

func _move(delta: float) -> void:
	_time += delta
	_vy = minf(_vy + accel * delta, speed)
	position.y += _vy * delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		position.x = move_toward(position.x, player.global_position.x, homing_speed * delta)
	var view := get_viewport_rect().size
	position.x = clampf(position.x, 16.0, view.x - 16.0)
	if position.y > view.y + 32.0:
		queue_free()
