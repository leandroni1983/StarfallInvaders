extends Node2D
class_name Explosion

## Efecto de explosión dibujado por código (flash + anillo + escombros).
## Aprovecha _draw() para no depender de partículas GPU (Compatibility-friendly).
## Efecto PROVISIONAL: se puede reemplazar por una animación de sprites.

@export var duration: float = 0.42
@export var radius: float = 18.0
@export var shard_count: int = 7
@export var hue: Color = Color("ffcf5e")

var _t: float = 0.0
var _shards: Array = [] # [{dir: Vector2, speed: float, size: float}]

func _ready() -> void:
	z_index = 5
	_build_shards()

func _build_shards() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in shard_count:
		var angle := TAU * float(i) / float(shard_count) + rng.randf_range(-0.3, 0.3)
		_shards.append({
			"dir": Vector2(cos(angle), sin(angle)),
			"speed": rng.randf_range(40.0, 95.0),
			"size": rng.randf_range(1.0, 2.5),
		})

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= duration:
		queue_free()

func _draw() -> void:
	var p := clampf(_t / duration, 0.0, 1.0)
	var alpha := 1.0 - p

	# Flash central.
	var flash_r := radius * (0.35 + p * 0.9)
	draw_circle(Vector2.ZERO, flash_r, Color(1.0, 0.96, 0.7, alpha * 0.85))
	draw_circle(Vector2.ZERO, flash_r * 0.55, Color(1.0, 1.0, 1.0, alpha))

	# Anillo en expansión.
	var ring_r := radius * (0.4 + p * 1.3)
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 28, Color(hue.r, hue.g, hue.b, alpha * 0.9), 2.0)

	# Escombros.
	for s in _shards:
		var pos: Vector2 = s["dir"] * s["speed"] * _t
		draw_circle(pos, s["size"], Color(hue.r, hue.g * 0.6, hue.b * 0.3, alpha))
