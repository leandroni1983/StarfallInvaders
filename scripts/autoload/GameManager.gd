extends Node

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over
signal game_started
signal weapon_changed(level: int)
signal shield_changed(amount: int)
signal bombs_changed(amount: int)
## Pide a la escena principal que agite la cámara (impactos, bombas, jefes).
signal shake_requested(amount: float)

## Nivel máximo de mejora de arma (disparo 1 -> 2 -> 3).
const MAX_WEAPON := 3
## Bombas que se pueden acumular.
const MAX_BOMBS := 3

## Dificultades que se eligen en la pantalla de inicio.
enum Difficulty { NORMAL, HARD }

## Dificultad de la partida en curso (se fija desde el menú).
var difficulty: int = Difficulty.NORMAL

var score: int = 0
var high_score: int = 0
var lives: int = 3
var max_lives: int = 3
var game_running: bool = false

# --- Mejoras de la partida en curso ---------------------------------------
var weapon_level: int = 1  # 1..MAX_WEAPON
var shield: int = 0        # 0..1 (absorbe un impacto)
var bombs: int = 0         # 0..MAX_BOMBS (se gastan con la acción "bomb")

func _ready() -> void:
	load_high_score()

func start_game() -> void:
	max_lives = start_lives()
	score = 0
	lives = max_lives
	weapon_level = 1
	shield = 0
	bombs = 0
	game_running = true
	score_changed.emit(score)
	lives_changed.emit(lives)
	_emit_items()
	game_started.emit()

# ---------------------------------------------------------------------------
# Dificultad
# ---------------------------------------------------------------------------
func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, Difficulty.size() - 1)

func is_hard() -> bool:
	return difficulty == Difficulty.HARD

func difficulty_name() -> String:
	return "DIFÍCIL" if is_hard() else "NORMAL"

## Vidas iniciales (menos margen en difícil).
func start_lives() -> int:
	return 2 if is_hard() else 3

## Velocidad de los enemigos (más rápidos en difícil).
func enemy_speed_mult() -> float:
	return 1.35 if is_hard() else 1.0

## Multiplicador de cadencia de disparo enemigo (<1 = dispara más seguido).
func enemy_fire_mult() -> float:
	return 0.75 if is_hard() else 1.0

## Vida extra para cada enemigo en difícil.
func enemy_hp_bonus() -> int:
	return 1 if is_hard() else 0

## Probabilidad de que caiga una mejora (<1 = menos ayudas en difícil).
func drop_chance_mult() -> float:
	return 0.7 if is_hard() else 1.0

## Puntos ganados (recompensa por arriesgar en difícil).
func score_mult() -> float:
	return 1.5 if is_hard() else 1.0

func add_score(points: int) -> void:
	score += int(round(float(points) * score_mult()))
	score_changed.emit(score)
	if score > high_score:
		high_score = score

## Solicita un sacudón de cámara (intensidad en píxeles). Lo maneja Main.
func request_shake(amount: float) -> void:
	if amount <= 0.0:
		return
	shake_requested.emit(amount)

func lose_life() -> void:
	if not game_running: return
	# Arcade clásico: al recibir daño se pierde la mejora de arma y el escudo.
	weapon_level = 1
	shield = 0
	_emit_items()
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		game_running = false

func reset_game() -> void:
	max_lives = start_lives()
	score = 0
	lives = max_lives
	weapon_level = 1
	shield = 0
	bombs = 0
	game_running = true
	score_changed.emit(score)
	lives_changed.emit(lives)
	_emit_items()

# ---------------------------------------------------------------------------
# Mejoras (power-ups)
# ---------------------------------------------------------------------------
func upgrade_weapon() -> void:
	weapon_level = mini(weapon_level + 1, MAX_WEAPON)
	weapon_changed.emit(weapon_level)

func add_shield() -> void:
	shield = 1
	shield_changed.emit(shield)

## Consume el escudo si lo hay. Devuelve true si absorbió el impacto.
func consume_shield() -> bool:
	if shield <= 0:
		return false
	shield -= 1
	shield_changed.emit(shield)
	return true

func add_bomb() -> void:
	bombs = mini(bombs + 1, MAX_BOMBS)
	bombs_changed.emit(bombs)

## Gasta una bomba. Devuelve true si había carga disponible.
func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	bombs_changed.emit(bombs)
	return true

func _emit_items() -> void:
	weapon_changed.emit(weapon_level)
	shield_changed.emit(shield)
	bombs_changed.emit(bombs)

func load_high_score() -> void:
	high_score = SaveManager.get_high_score()

func save_high_score() -> void:
	if score > high_score:
		high_score = score
	SaveManager.save_high_score(high_score)
