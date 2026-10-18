extends CanvasLayer
class_name HUD

## El botón de bomba de pantalla emite esta señal; Main la conecta a `_use_bomb`.
signal bomb_pressed
## El botón de pausa de pantalla emite esta señal; Main la conecta a `toggle_pause`.
signal pause_pressed
## El menú de inicio emite esta señal con la dificultad elegida.
signal start_requested(difficulty: int)

@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var item_label: Label = $ItemLabel
@onready var status_label: Label = $CenterPanel/StatusLabel
@onready var center_panel: Control = $CenterPanel
@onready var game_over_logo: TextureRect = $CenterPanel/GameOverLogo
@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_label: Label = $BossLabel
@onready var bomb_button: Button = $BombButton
@onready var pause_button: Button = $PauseButton
@onready var flash_rect: ColorRect = $Flash
@onready var combo_label: Label = $ComboLabel
@onready var message_label: Label = $MessageLabel

@onready var start_panel: Control = $StartPanel
@onready var start_high_label: Label = $StartPanel/HighLabel
@onready var start_desc_label: Label = $StartPanel/DescLabel
@onready var normal_button: Button = $StartPanel/NormalButton
@onready var hard_button: Button = $StartPanel/HardButton

var _selected_difficulty: int = GameManager.Difficulty.NORMAL

## Tween del pulso del aviso de jefe; se cancela al cambiar de texto.
var _warn_tween: Tween = null

## Tween del titileo del mensaje de los jefes.
var _msg_tween: Tween = null
## Identificador del mensaje en curso (para que uno viejo no oculte a uno nuevo).
var _msg_id: int = 0

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.weapon_changed.connect(_on_items_changed)
	GameManager.bombs_changed.connect(_on_items_changed)
	bomb_button.pressed.connect(_on_bomb_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	normal_button.pressed.connect(_on_difficulty_clicked.bind(GameManager.Difficulty.NORMAL))
	hard_button.pressed.connect(_on_difficulty_clicked.bind(GameManager.Difficulty.HARD))
	_set_lives(GameManager.lives)
	_set_score(GameManager.score)
	_set_high(GameManager.high_score)
	_on_items_changed(0)

# ---------------------------------------------------------------------------
# Menú de inicio (selección de dificultad)
# ---------------------------------------------------------------------------
func _on_difficulty_clicked(difficulty: int) -> void:
	_selected_difficulty = difficulty
	_update_difficulty_ui()
	_confirm_start()

func _confirm_start() -> void:
	start_panel.visible = false
	start_requested.emit(_selected_difficulty)

func _update_difficulty_ui() -> void:
	var normal_sel := _selected_difficulty == GameManager.Difficulty.NORMAL
	normal_button.modulate = Color(1, 1, 1) if normal_sel else Color(0.55, 0.55, 0.6)
	hard_button.modulate = Color(1, 1, 1) if not normal_sel else Color(0.55, 0.55, 0.6)
	if normal_sel:
		start_desc_label.text = "3 vidas · enemigos clásicos\nIdeal para empezar."
	else:
		start_desc_label.text = "2 vidas · enemigos más rápidos y resistentes\nPuntaje ×1,5"

func _unhandled_input(event: InputEvent) -> void:
	if not start_panel.visible:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") \
			or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		_selected_difficulty = GameManager.Difficulty.NORMAL if _selected_difficulty == GameManager.Difficulty.HARD else GameManager.Difficulty.HARD
		_update_difficulty_ui()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_confirm_start()
		get_viewport().set_input_as_handled()

func _on_bomb_pressed() -> void:
	bomb_pressed.emit()

func _on_pause_pressed() -> void:
	pause_pressed.emit()

func _on_items_changed(_v: int) -> void:
	item_label.text = "PWR %d  BOMB %d" % [GameManager.weapon_level, GameManager.bombs]

func _set_score(v: int) -> void:
	score_label.text = "SCORE %d" % v

func _set_high(v: int) -> void:
	high_score_label.text = "HI %d" % v

func _set_lives(v: int) -> void:
	var s := ""
	for i in range(GameManager.max_lives):
		s += "♥ " if i < v else "· "
	lives_label.text = s.strip_edges()

func _on_score_changed(v: int) -> void:
	_set_score(v)
	_set_high(GameManager.high_score)

func _on_lives_changed(v: int) -> void:
	_set_lives(v)

# ---------------------------------------------------------------------------
# Overlays
# ---------------------------------------------------------------------------
func show_text(msg: String) -> void:
	_kill_warn_tween()
	hide_combo()
	start_panel.visible = false
	center_panel.visible = true
	bomb_button.visible = false
	pause_button.visible = false
	status_label.modulate = Color.WHITE
	status_label.text = msg

## Aviso de peligro (aparición de jefe): texto rojo pulsante.
func show_warning(title: String, subtitle: String = "") -> void:
	_kill_warn_tween()
	start_panel.visible = false
	center_panel.visible = true
	bomb_button.visible = false
	pause_button.visible = false
	status_label.text = title if subtitle.is_empty() else "%s\n\n%s" % [title, subtitle]
	status_label.modulate = Color(1, 1, 1)
	_warn_tween = create_tween().set_loops(4)
	_warn_tween.tween_property(status_label, "modulate", Color(1.0, 0.25, 0.25), 0.18)
	_warn_tween.tween_property(status_label, "modulate", Color(1.0, 1.0, 1.0), 0.18)

func _kill_warn_tween() -> void:
	if _warn_tween != null and _warn_tween.is_valid():
		_warn_tween.kill()
	_warn_tween = null

func hide_text() -> void:
	_kill_warn_tween()
	center_panel.visible = false
	status_label.text = ""

## Destello breve a pantalla completa (p. ej. al usar una bomba).
func flash() -> void:
	flash_rect.color = Color(1, 1, 1, 0.55)
	var tween := create_tween()
	tween.tween_property(flash_rect, "color", Color(1, 1, 1, 0.0), 0.35)

# ---------------------------------------------------------------------------
# Combo (rachas de bajas)
# ---------------------------------------------------------------------------
## Muestra la racha actual. A partir de 2 bajas encadena; se oculta por debajo.
func show_combo(count: int) -> void:
	if count < 2:
		hide_combo()
		return
	combo_label.visible = true
	combo_label.text = "COMBO x%d" % count
	# Cuanto mayor la racha, más cálido el color.
	var heat := clampf(float(count - 2) / 8.0, 0.0, 1.0)
	combo_label.modulate = Color(1.0, lerpf(0.95, 0.55, heat), lerpf(0.7, 0.15, heat))

func hide_combo() -> void:
	combo_label.visible = false

# ---------------------------------------------------------------------------
# Mensaje titilante (frases de los jefes)
# ---------------------------------------------------------------------------
## Muestra un mensaje centrado que titila sobre la partida durante `duration`
## segundos (frase de entrada de un jefe, agradecimiento del alma liberada…).
## No bloquea el juego: se oculta solo al terminar, o antes si lo reemplaza
## otro mensaje. `show_message` es asíncrona: llamala sin `await`.
func show_message(msg: String, duration: float = 5.0) -> void:
	_msg_id += 1
	var id := _msg_id
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	message_label.text = msg
	message_label.modulate = Color(1, 1, 1, 1)
	message_label.visible = true
	# Titileo: baja y sube la opacidad en un ciclo continuo (sin llegar a
	# desaparecer del todo, para que siempre se pueda leer).
	_msg_tween = create_tween().set_loops()
	_msg_tween.tween_property(message_label, "modulate:a", 0.45, 0.32)
	_msg_tween.tween_property(message_label, "modulate:a", 1.0, 0.32)
	await get_tree().create_timer(duration).timeout
	if id == _msg_id:
		hide_message()

func hide_message() -> void:
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = null
	if message_label != null:
		message_label.visible = false

func show_start(high: int) -> void:
	_kill_warn_tween()
	hide_message()
	center_panel.visible = false
	bomb_button.visible = false
	pause_button.visible = false
	hide_combo()
	start_high_label.text = "RÉCORD %d" % high
	_selected_difficulty = GameManager.difficulty
	_update_difficulty_ui()
	start_panel.visible = true

func hide_start() -> void:
	start_panel.visible = false

func show_game_over(score: int, high: int) -> void:
	game_over_logo.visible = true
	hide_message()
	var label_text := "GAME OVER\n\nPUNTOS %d\nRÉCORD %d\nDIFICULTAD: %s\n\nTOCÁ PARA REINTENTAR" % [score, high, GameManager.difficulty_name()]
	status_label.text = label_text
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.offset_bottom = -40.0
	center_panel.visible = true
	bomb_button.visible = false
	pause_button.visible = false

func show_victory(score: int, high: int) -> void:
	show_text("VICTORIA\n\nPUNTOS %d\nRECORD %d\n\nTOCÁ PARA JUGAR DE NUEVO" % [score, high])

func show_pause() -> void:
	show_text("PAUSA\n\nTOCÁ LA PANTALLA\nPARA CONTINUAR")

func show_playing() -> void:
	hide_text()
	start_panel.visible = false
	bomb_button.visible = true
	pause_button.visible = true

# ---------------------------------------------------------------------------
# Barra de vida del jefe
# ---------------------------------------------------------------------------
func show_boss(max_hp: int) -> void:
	boss_bar.visible = true
	boss_label.visible = true
	set_boss_hp(max_hp, max_hp)

func set_boss_hp(current: int, maximum: int) -> void:
	boss_bar.max_value = maxf(1.0, float(maximum))
	boss_bar.value = clampf(float(current), 0.0, boss_bar.max_value)

func hide_boss() -> void:
	boss_bar.visible = false
	boss_label.visible = false
