extends Node

## SpriteFactory
##
## Genera texturas de pixel art ORIGINALES en tiempo de ejecución a partir de
## mapas ASCII y una paleta de colores. No depende de archivos de imagen
## externos, por lo que el proyecto es totalmente autocontenido.
##
## NOTA: Estos recursos son PROVISIONALES. Cumplen el requisito de "recursos
## originales creados mediante formas/polígonos/sprites propios" y pueden ser
## reemplazados por sprites PNG definitivos sin cambiar la lógica del juego:
## basta con asignar una ImageTexture (o Texture2D) al Sprite2D correspondiente.

const _TRANSPARENT := "."

var _cache: Dictionary = {}

# ---------------------------------------------------------------------------
# Paletas
# ---------------------------------------------------------------------------
const PALETTE_PLAYER := {
	"C": Color("2fd6ff"), # casco cian
	"W": Color("eafcff"), # cabina blanca
	"B": Color("1170b8"), # sombra azul
	"O": Color("ff9a2e"), # motor
	"Y": Color("ffe45e"), # llama
}

const PALETTE_GRUNT := {
	"R": Color("e0433a"), # rojo
	"D": Color("8f1f22"), # rojo oscuro
	"K": Color("2b0d14"), # núcleo
	"Y": Color("ffd23f"), # punto débil
}

const PALETTE_WEAVER := {
	"P": Color("a05bff"), # violeta
	"D": Color("5e2fa8"), # violeta oscuro
	"W": Color("efe4ff"), # brillo
	"Y": Color("4fe0c8"), # acento
}

const PALETTE_MINION := {
	"G": Color("3ddc84"), # verde
	"D": Color("1f8f52"), # verde oscuro
	"C": Color("eafff2"), # cabina
	"Y": Color("ffe45e"), # motor
}

const PALETTE_DIVER := {
	"O": Color("ff8a2b"), # naranja
	"D": Color("c24a12"), # naranja oscuro
	"Y": Color("fff0a0"), # núcleo
}

const PALETTE_SNIPER := {
	"B": Color("4a7bd6"), # azul acero
	"W": Color("dbe9ff"), # brillo
	"K": Color("101a33"), # lente
	"Y": Color("66e0ff"), # acento
}

# "Navecita" de Farol Faina: porción de pizza (borde, queso y pepperoni).
const PALETTE_PIZZA := {
	"B": Color("8a4b1e"), # borde tostado
	"Q": Color("d9922f"), # masa
	"Y": Color("ffd23f"), # queso
	"O": Color("ff9a2e"), # queso fundido
	"R": Color("d62b2b"), # pepperoni
}

const PALETTE_PU_WEAPON := {
	"C": Color("2fd6ff"),
	"L": Color("eafcff"),
}

const PALETTE_PU_SHIELD := {
	"G": Color("3ddc84"),
	"L": Color("eafff2"),
}

const PALETTE_PU_BOMB := {
	"M": Color("ff5ea8"),
	"Y": Color("ffe45e"),
}

const PALETTE_SHIELD_RING := {
	"S": Color("6fe8ff"),
	"L": Color("d6f6ff"),
}

const PALETTE_FX := {
	"Y": Color("fff2a8"),
	"O": Color("ff9a2e"),
	"R": Color("e0433a"),
}

# ---------------------------------------------------------------------------
# Mapas ASCII
# ---------------------------------------------------------------------------
const PLAYER_SHIP: PackedStringArray = [
	"......C......",
	".....CCC.....",
	".....CWC.....",
	"....CCWCC....",
	"....CCWCC....",
	"...BCCWCCB...",
	"...BCWWWCB...",
	"..BBCCWCCBB..",
	".BBCCCCCCCBB.",
	"BB.CCCCCCC.BB",
	"B...CCCCC...B",
	"......O......",
	".....OYO.....",
]

const ENEMY_GRUNT: PackedStringArray = [
	"R.........R",
	"RR.......RR",
	"RRR.....RRR",
	"DRRR...RRRD",
	".DRRRRRRRD.",
	"..RRKKKRR..",
	"..DRKKKRD..",
	"...RRRRR...",
	"....DYD....",
	".....R.....",
	".....R.....",
]

const ENEMY_WEAVER: PackedStringArray = [
	"..P.....P..",
	".PPP...PPP.",
	".PPDP.PDPP.",
	"..PPDPDPP..",
	"..DPPWWPD..",
	"...PWWWP...",
	"..DPPWWPD..",
	".PPDP.PDPP.",
	".PPP...PPP.",
	"..P..Y..P..",
	"...P...P...",
]

# "Navecita": caza pequeña que el jefe lanza en enjambre. Apunta hacia abajo
# (motores arriba, morro abajo).
const ENEMY_MINION: PackedStringArray = [
	"..Y.Y..",
	"..G.G..",
	".GGCGG.",
	"GGGCGGG",
	".GGGGG.",
	".GGGGG.",
	".....",
]

# "Diver" (kamikaze): dardo naranja que se lanza hacia el jugador.
const ENEMY_DIVER: PackedStringArray = [
	"O.........O",
	"OO.......OO",
	".OO.....OO.",
	"..OO...OO..",
	"...OO.OO...",
	"...OOYOO...",
	"....OYO....",
	"....D.D....",
	".....D.....",
]
# "Sniper": nave azul con un lente/visor central que apunta al jugador.
const ENEMY_SNIPER: PackedStringArray = [
	"...BBB...",
	"..BBBBB..",
	".BBWWWBB.",
	"BBKKKKKBB",
	"BBWKKKWBB",
	"BBKKKKKBB",
	".BBWWWBB.",
	"..BBBBB..",
	"...BYB...",
	"....B....",
]

# --- Objetos (power-ups) ---------------------------------------------------
# Doble chevrón hacia arriba: mejora de arma.
const PU_WEAPON: PackedStringArray = [
	"...C...",
	"..CCC..",
	".CCCCC.",
	"CCCCCCC",
	"...C...",
	"..CCC..",
	".CCCCC.",
]

# Anillo/escudo.
const PU_SHIELD: PackedStringArray = [
	"..GGG..",
	".GLLLG.",
	"GLL.LLG",
	"GL...LG",
	"GLL.LLG",
	".GLLLG.",
	"..GGG..",
]

# Bomba con mecha.
const PU_BOMB: PackedStringArray = [
	"...Y...",
	"..YMY..",
	".MMMMM.",
	"MMMYMMM",
	"MMMYMMM",
	".MMMMM.",
	"..MMM..",
]

# Aro de escudo que rodea la nave del jugador mientras está activo.
const SHIELD_RING: PackedStringArray = [
	"..SSSSS..",
	".S.....S.",
	"S.......S",
	"S...L...S",
	"S.......S",
	"S.......S",
	".S.....S.",
	"..SSSSS..",
]

# Proyectil del jugador: diamante cian alargado verticalmente.
const BULLET_PLAYER: PackedStringArray = [
	".C.",
	"CWC",
	"CWC",
	".C.",
	".C.",
]

# Proyectil enemigo: orbe rojo/naranja.
const BULLET_ENEMY: PackedStringArray = [
	".RRR.",
	"ROYOR",
	"RYYYR",
	"ROYOR",
	".RRR.",
]

const STAR_SMALL: PackedStringArray = [
	"W",
]

# PIZZA: porción de pizza (triángulo con borde crujiente y pepperoni). Es el
# aspecto de las "navecitas" que lanza el jefe Farol Faina.
const PIZZA_SLICE: PackedStringArray = [
	"BBBBBBBBB",
	"QQQQQQQQQ",
	".YYYYYYY.",
	".YYRYYYY.",
	"..YYYYY..",
	"..YRYRY..",
	"...YYY...",
	"...YOY...",
	"....Y....",
]

# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------
func player_ship() -> Texture2D:
	return _make("player_ship", PLAYER_SHIP, PALETTE_PLAYER)

func enemy_grunt() -> Texture2D:
	return _make("enemy_grunt", ENEMY_GRUNT, PALETTE_GRUNT)

func enemy_weaver() -> Texture2D:
	return _make("enemy_weaver", ENEMY_WEAVER, PALETTE_WEAVER)

func enemy_minion() -> Texture2D:
	return _make("enemy_minion", ENEMY_MINION, PALETTE_MINION)

func enemy_diver() -> Texture2D:
	return _make("enemy_diver", ENEMY_DIVER, PALETTE_DIVER)

func enemy_sniper() -> Texture2D:
	return _make("enemy_sniper", ENEMY_SNIPER, PALETTE_SNIPER)

func powerup_weapon() -> Texture2D:
	return _make("pu_weapon", PU_WEAPON, PALETTE_PU_WEAPON)

func powerup_shield() -> Texture2D:
	return _make("pu_shield", PU_SHIELD, PALETTE_PU_SHIELD)

func powerup_bomb() -> Texture2D:
	return _make("pu_bomb", PU_BOMB, PALETTE_PU_BOMB)

func shield_ring() -> Texture2D:
	return _make("shield_ring", SHIELD_RING, PALETTE_SHIELD_RING)

func bullet_player() -> Texture2D:
	return _make("bullet_player", BULLET_PLAYER, PALETTE_PLAYER)

func pizza_slice() -> Texture2D:
	return _make("pizza_slice", PIZZA_SLICE, PALETTE_PIZZA)

func bullet_enemy() -> Texture2D:
	return _make("bullet_enemy", BULLET_ENEMY, PALETTE_GRUNT)

func star() -> Texture2D:
	return _make("star", STAR_SMALL, {"W": Color.WHITE})

# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------
func _make(key: String, rows: PackedStringArray, palette: Dictionary) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var h: int = rows.size()
	var w: int = 0
	for r in rows:
		w = maxi(w, r.length())
	if w == 0 or h == 0:
		push_error("SpriteFactory: mapa vacío para '%s'" % key)
		return null
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var ch: String = row[x]
			if ch == _TRANSPARENT or ch == " ":
				continue
			if not palette.has(ch):
				continue
			img.set_pixel(x, y, palette[ch])
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
