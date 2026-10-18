extends EnemyBase
class_name EnemyMinion

## "Navecita": caza pequeña que el jefe lanza como enjambre.
##
## Es rápida y frágil (muere de un solo impacto). Desciende con un ligero
## zigzag (cada una con fase aleatoria) y dispara apuntando al jugador.

@export var amplitude: float = 14.0
@export var frequency: float = 6.0

var _origin_x: float = 0.0
var _phase: float = 0.0

func _sprite_texture() -> Texture2D:
	return SpriteFactory.enemy_minion()

func _ready() -> void:
	super._ready()
	_phase = randf() * TAU
	reset_origin()

## Fija el centro del zigzag con la posición actual. Necesario porque el jefe
## asigna la posición DESPUÉS de add_child(_ready ya corrió).
func reset_origin() -> void:
	_origin_x = position.x

func _move(delta: float) -> void:
	_time += delta
	position.y += speed * delta
	position.x = _origin_x + sin(_time * frequency + _phase) * amplitude
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
