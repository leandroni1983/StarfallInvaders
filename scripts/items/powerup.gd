extends Area2D
class_name PowerUp

## Objeto recogible que sueltan los enemigos al morir. Desciende lentamente y,
## al tocar al jugador, aplica su mejora correspondiente.

enum Kind { WEAPON, SHIELD, BOMB }

@export var kind: int = Kind.WEAPON
@export var fall_speed: float = 92.0

@onready var sprite: Sprite2D = $Sprite2D

var _time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.texture = _texture()
		_pulse()

func _texture() -> Texture2D:
	match kind:
		Kind.SHIELD: return SpriteFactory.powerup_shield()
		Kind.BOMB: return SpriteFactory.powerup_bomb()
		_: return SpriteFactory.powerup_weapon()

func _process(delta: float) -> void:
	_time += delta
	position.y += fall_speed * delta
	rotation = sin(_time * 3.0) * 0.25
	if position.y > get_viewport_rect().size.y + 32.0:
		queue_free()

## Latido para que el objeto se distinga y llame la atención.
func _pulse() -> void:
	if sprite == null:
		return
	sprite.scale = Vector2(1.6, 1.6)
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "scale", Vector2(2.1, 2.1), 0.45)
	tween.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.45)

func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	apply()
	queue_free()

## Aplica la mejora al estado de la partida. Separado para poder testearlo.
func apply() -> void:
	AudioManager.play_sfx("powerup")
	match kind:
		Kind.SHIELD:
			GameManager.add_shield()
		Kind.BOMB:
			GameManager.add_bomb()
		_:
			GameManager.upgrade_weapon()
