extends EnemyBase
class_name EnemySniper

## "Sniper": desciende hasta una altura, se detiene a apuntar y dispara al
## jugador; tras unos segundos reanuda el descenso y sale de pantalla. Muere de
## un solo impacto.

enum S { ENTER, HOVER, LEAVE }

@export var hover_y: float = 170.0
@export var hover_time: float = 2.6
@export var drift: float = 18.0

var _state: int = S.ENTER
var _hover_left: float = 0.0
var _origin_x: float = 0.0

func _sprite_texture() -> Texture2D:
	return SpriteFactory.enemy_sniper()

func _ready() -> void:
	super._ready()
	_origin_x = position.x
	_hover_left = hover_time

func _move(delta: float) -> void:
	_time += delta
	match _state:
		S.ENTER:
			position.y += speed * delta
			if position.y >= hover_y:
				position.y = hover_y
				_state = S.HOVER
		S.HOVER:
			_hover_left -= delta
			position.x = _origin_x + sin(_time * 1.6) * drift
			if _hover_left <= 0.0:
				_state = S.LEAVE
		S.LEAVE:
			position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 32.0:
		queue_free()

## Dispara apuntando al jugador (si lo encuentra); si no, hacia abajo.
func _on_shoot_timeout() -> void:
	if not GameManager.game_running:
		return
	var dir := Vector2.DOWN
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		dir = (player.global_position - fire_point.global_position).normalized()
	_spawn_bullet_dir(dir)
