extends SceneTree

## Comprobación rápida de que los sprites de los jefes cargan de verdad
## (importación válida y decodificable), sin abrir ventana ni el juego.
##
##   godot --headless --path . --script res://tools/check_textures.gd

const PATHS := [
	"res://assets/sprites/bosses/boss_juampi_evil.png",
	"res://assets/sprites/bosses/boss_juampi_angel.png",
	"res://assets/sprites/bosses/boss_infe.png",
	"res://assets/sprites/bosses/serial_te.png",
	"res://assets/sprites/bosses/farol_faina.png",
	"res://assets/sprites/ui/title_logo.png",
	"res://assets/sprites/ui/app_icon.png",
]

func _initialize() -> void:
	var bad := 0
	for p in PATHS:
		var exists := ResourceLoader.exists(p)
		var tex: Texture2D = load(p) if exists else null
		if tex == null:
			bad += 1
		print("[TEX] %s existe=%s carga=%s tamaño=%s" % [
			p, exists, tex != null, tex.get_size() if tex != null else Vector2.ZERO
		])
	print("[TEX] fallos=%d" % bad)
	quit(1 if bad > 0 else 0)
