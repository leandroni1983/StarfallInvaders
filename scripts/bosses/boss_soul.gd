class_name BossSoul
extends Node2D

## "Alma" del jefe: cuando cae el jefe poseído aparece su forma liberada (el
## ángel) flotando, con un latido de halo, mientras destellan estrellitas y
## corazoncitos alrededor.
##
## Es puramente decorativo: no colisiona, no cuenta como enemigo y no altera el
## flujo de la partida (el ciclo sube igual y la invasión continúa). Se
## autodestruye al terminar su tiempo de vida o al limpiar el mundo.
##
## Se usa desde código: `var s := BossSoul.new(); s.texture = tex; add_child(s)`.

## Sprite de la forma liberada (obligatorio).
var texture: Texture2D = null
## Cuántos segundos permanece antes de desvanecerse.
var lifetime: float = 6.5
## Escala del sprite (el original mide 512×512).
var sprite_scale: float = 0.28

const GOLD := Color(1.0, 0.87, 0.35)
const PINK := Color(1.0, 0.42, 0.62)

var _t: float = 0.0
var _sprite: Sprite2D = null
## Cada motivo: {offset, size, phase, speed, drift, heart}.
var _motifs: Array = []

func _ready() -> void:
	z_index = 40
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 14:
		_motifs.append({
			"offset": Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-125.0, 130.0)),
			"size": rng.randf_range(5.0, 11.0),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(2.2, 4.2),
			"drift": rng.randf_range(8.0, 26.0),
			"heart": i % 3 == 0,
		})

func _process(delta: float) -> void:
	_t += delta
	if _sprite != null:
		# Flotación suave y halo que "respira".
		_sprite.position.y = sin(_t * 1.8) * 7.0
		var glow := 0.85 + 0.15 * sin(_t * 4.0)
		_sprite.modulate = Color(glow, glow, glow, _alpha())
	queue_redraw()
	if _t >= lifetime:
		queue_free()

## Entra rápido y se desvanece en el último tramo de su vida.
func _alpha() -> float:
	return clampf(minf(_t * 2.5, (lifetime - _t) / 1.6), 0.0, 1.0)

func _draw() -> void:
	var fade := _alpha()
	for m in _motifs:
		var twinkle := 0.45 + 0.55 * absf(sin(_t * float(m.speed) + float(m.phase)))
		var pos: Vector2 = m.offset + Vector2(0.0, sin(_t * 1.4 + float(m.phase)) * float(m.drift))
		var size := float(m.size) * (0.72 + 0.35 * twinkle)
		var color := PINK if bool(m.heart) else GOLD
		color.a = twinkle * fade
		if bool(m.heart):
			_draw_heart(pos, size, color)
		else:
			_draw_star(pos, size, color)

## Corazón por curva paramétrica (sin depender de ninguna textura).
func _draw_heart(center: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var t := TAU * float(i) / 32.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(center + Vector2(x, -y) * (size / 16.0))
	draw_colored_polygon(pts, color)

## Estrella de cinco puntas.
func _draw_star(center: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var r := size if i % 2 == 0 else size * 0.45
		var a := -PI * 0.5 + PI * float(i) / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, color)
