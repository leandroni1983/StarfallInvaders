extends Node2D
class_name Starfield

## Fondo espacial procedural: estrellas en scroll vertical (parallax) y
## nebulosas lejanas dibujadas en _draw(). PROVISIONAL y muy ligero.
## Se puede reemplazar por sprites/tiles definitivos sin tocar su API pública.

@export var star_count: int = 70
@export var base_speed: float = 40.0
@export var nebula_color: Color = Color(0.28, 0.16, 0.5, 0.18)
@export var planet_enabled: bool = true

var _stars: Array = [] # [{y, x, speed, size, bright}]
var _view_size: Vector2 = Vector2(360.0, 640.0)
var _rng := RandomNumberGenerator.new()

# Planeta de fondo: cambia de posición/color en cada ciclo para dar variedad.
var _cycle: int = 0
var _planet_pos: Vector2 = Vector2.ZERO
var _planet_radius: float = 34.0
var _planet_hue: float = 0.0

func _ready() -> void:
	z_index = -10
	_rng.randomize()
	_view_size = get_viewport_rect().size
	_spawn_stars()
	_roll_planet()

func _spawn_stars() -> void:
	_stars.clear()
	for i in star_count:
		_stars.append({
			"x": _rng.randf_range(0.0, _view_size.x),
			"y": _rng.randf_range(0.0, _view_size.y),
			"speed": base_speed * _rng.randf_range(0.4, 2.2),
			"size": _rng.randf_range(1.0, 2.4),
			"bright": _rng.randf_range(0.35, 1.0),
		})

func _process(delta: float) -> void:
	var bottom := _view_size.y
	for s in _stars:
		s["y"] = float(s["y"]) + float(s["speed"]) * delta
		if float(s["y"]) > bottom:
			s["y"] = -4.0
			s["x"] = _rng.randf_range(0.0, _view_size.x)
	queue_redraw()

func _draw() -> void:
	# Nebulosas lejanas (círculos translúcidos grandes).
	draw_circle(Vector2(_view_size.x * 0.75, _view_size.y * 0.25), 120.0, nebula_color)
	draw_circle(Vector2(_view_size.x * 0.2, _view_size.y * 0.65), 150.0, nebula_color * Color(1, 1, 1, 0.7))

	# Planeta lejano (color/posición según el ciclo actual).
	if planet_enabled:
		_draw_planet()

	# Estrellas.
	for s in _stars:
		var c := float(s["bright"])
		draw_circle(Vector2(float(s["x"]), float(s["y"])), float(s["size"]), Color(c, c, c * 0.95, 1.0))

func _draw_planet() -> void:
	var base := Color.from_hsv(_planet_hue, 0.45, 0.55)
	var dark := Color.from_hsv(fmod(_planet_hue + 0.08, 1.0), 0.55, 0.28)
	# Anillo inclinado detrás del cuerpo.
	draw_set_transform(_planet_pos, -0.35, Vector2(1.0, 0.32))
	draw_arc(Vector2.ZERO, _planet_radius * 1.7, 0.0, TAU, 40, Color(base.r, base.g, base.b, 0.5), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Cuerpo y sombra (fase).
	draw_circle(_planet_pos, _planet_radius, base)
	draw_circle(_planet_pos + Vector2(_planet_radius * 0.4, _planet_radius * 0.2), _planet_radius * 0.92, Color(dark.r, dark.g, dark.b, 0.85))
	# Brillo superior.
	draw_circle(_planet_pos - Vector2(_planet_radius * 0.35, _planet_radius * 0.4), _planet_radius * 0.28, Color(1, 1, 1, 0.35))

## Cambia el aspecto del fondo al empezar un ciclo nuevo (variedad visual).
func set_cycle(cycle: int) -> void:
	_cycle = cycle
	_roll_planet()

func _roll_planet() -> void:
	_planet_hue = fmod(0.62 + float(_cycle) * 0.17, 1.0)
	_planet_radius = _rng.randf_range(24.0, 42.0)
	_planet_pos = Vector2(
		_rng.randf_range(_view_size.x * 0.18, _view_size.x * 0.82),
		_rng.randf_range(70.0, _view_size.y * 0.55))
	# La nebulosa acompaña el tono del planeta (complementario).
	nebula_color = Color.from_hsv(fmod(_planet_hue + 0.5, 1.0), 0.6, 0.55, 0.16)
	queue_redraw()

func set_view_size(v: Vector2) -> void:
	_view_size = v
