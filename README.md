# Alonso Invader

Shoot 'em up vertical arcade 2D ambientado en el espacio. Proyecto original en
**Godot 4** (GDScript tipado), pensado para Android en orientación vertical y
también jugable en PC.

> Estado: **FASE 3 (progresión) completada.** Ver `ROADMAP.md`.

## Requisitos

- **Godot 4.7** (probado con `4.7.2.stable.official`). Compatible con Godot 4.x.
- Renderizador: **Compatibility** (OpenGL 3.3). No requiere Vulkan.

## Cómo ejecutar

### Desde el editor
1. Abrir Godot 4.
2. *Import* → seleccionar `project.godot` de la carpeta del proyecto.
3. Pulsar **F5** (Play).

### Desde línea de comandos

```powershell
# Sustituir la ruta por la del ejecutable de Godot
godot --path "C:\Users\Leandro\Desktop\StarfallInvaders"
```

En Windows, con el binario descargado:

```powershell
& "C:\Users\Leandro\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" `
  --path "C:\Users\Leandro\Desktop\StarfallInvaders"
```

## Controles

| Acción | Táctil (Android) | PC |
|---|---|---|
| Mover nave | Arrastrar el dedo | Flechas o `WASD` |
| Disparar | Automático | Automático |
| Lanzar bomba | Botón **BOMB** en pantalla | `B` o `Espacio` |
| Empezar / reiniciar | Tocar la pantalla | `Enter` o clic |
| Pausa | — | `Esc` |

El disparo es automático mientras se juega, como es habitual en el género.

## Estructura del proyecto

```
res://
├── project.godot
├── icon.svg
├── scenes/
│   ├── main/         main.tscn            (escena principal / orquestador)
│   ├── player/       player.tscn          (nave del jugador)
│   ├── enemies/      enemy_grunt.tscn, enemy_weaver.tscn, enemy_minion.tscn,
│   │                 enemy_diver.tscn, enemy_sniper.tscn
│   ├── projectiles/  player_bullet.tscn, enemy_bullet.tscn
│   ├── items/        powerup.tscn          (mejoras recogibles)
│   ├── effects/      explosion.tscn
│   ├── ui/           hud.tscn
│   ├── levels/       (reservado para FASE 2+)
│   └── bosses/       boss_01.tscn         (jefe de cada 10 oleadas)
├── scripts/
│   ├── autoload/     GameManager, SaveManager, AudioManager, SpriteFactory
│   ├── main/         main.gd
│   ├── player/       player.gd
│   ├── enemies/      enemy_base.gd, enemy_type1.gd, enemy_type2.gd,
│   │                 enemy_minion.gd, enemy_diver.gd, enemy_sniper.gd
│   ├── bosses/       boss_01.gd
│   ├── combat/       player_bullet.gd, enemy_bullet.gd
│   ├── items/        powerup.gd
│   ├── systems/      starfield.gd, explosion.gd
│   └── ui/           hud.gd
├── assets/           sprites/ (incl. sprites/bosses/boss_juampi_evil.png,
│                     boss_juampi_angel.png y boss_infe.png) backgrounds/ audio/ fonts/
├── source/           material original (ej. boss_01.webp); ignorado por Godot
├── data/             (reservado para datos de balance)
└── tests/            test_harness.gd, run_tests.ps1
```

## Arquitectura (resumen)

- **Autoloads**
  - `GameManager`: puntuación, vidas, señales (`score_changed`, `lives_changed`,
    `game_over`, `game_started`) y estado de partida. También guarda las
    **mejoras** de la partida en curso (`weapon_level`, `shield`, `bombs`) con sus
    señales (`weapon_changed`, `shield_changed`, `bombs_changed`).
  - `SaveManager`: persistencia local del récord en `user://save.dat`.
  - `SpriteFactory`: genera las texturas de pixel art originales en tiempo de
    ejecución (ver *Arte*).
  - `AudioManager`: sintetiza **efectos** (disparo, explosión, impacto, mejora,
    bomba, golpe de jefe, aviso, campanitas del alma liberada) y **música** en
    bucle (tema de partida y tema de jefe), sin usar archivos de audio externos.
- **Main** (`scenes/main/main.tscn`): máquina de estados
  (`START` / `PLAYING` / `GAMEOVER`), spawn de oleadas, aparición del jefe,
  pausa y limpieza. Agrupa el gameplay bajo `World` (pausable) y la UI bajo
  `HUD` (CanvasLayer).
- **Ciclos y dificultad**: la partida es **infinita**. Cada ciclo tiene
  `WAVES_PER_CYCLE` (10) oleadas y termina con un jefe. Al vencerlo sube la
  dificultad (`_cycle += 1`): más enemigos, más rápidos, disparan más seguido y
  el jefe tiene más vida/velocidad y lanza más navecitas.
- **Jugador**: `CharacterBody2D` con movimiento táctil (arrastre) y teclado,
  disparo automático por `Timer` y parpadeo de invulnerabilidad tras recibir daño.
- **Enemigos**: `Area2D` reutilizables. `EnemyBase` define vida, patrón de
  disparo y muerte. Tipos: `EnemyType1` (grunt con vaivén), `EnemyType2` (weaver
  senoidal), `EnemyMinion` ("navecita" rápida y frágil que dispara apuntando al
  jugador), `EnemyDiver` (kamikaze que corrige su rumbo hacia el jugador) y
  `EnemySniper` (baja, se detiene a apuntar y dispara al jugador).
- **Formaciones de oleada**: cada oleada del ciclo usa un patrón distinto
  (fila, V, flujo lateral, pinza, francotiradores, mezclas y enjambre de cierre).
- **Jefes**: `Boss01` "JUAMPI EVIL" y `Boss02` "EL INFE" (`Area2D`, ambos derivan
  de `EnemyBase`). Aparecen al completar cada ciclo (alternando entre uno y otro),
  patrullan, disparan (abanicos el primero, salvas el segundo) y lanzan
  **navecitas** (`EnemyMinion`) en enjambre. Emiten `health_changed` para la barra
  del HUD. `intro_message` muestra una frase titilante al entrar ("DAME MI
  PERUANITA AH AH AH" en el Infe) y `soul_texture_path` + `soul_message` disparan
  la escena del **alma liberada**: al morir Juampi Evil aparece el ángel
  (`BossSoul`: el sprite flotando + estrellitas y corazoncitos dibujados con
  `_draw` + campanitas `angel` + mensaje titilante "¡GRACIAS!… ROMPISTE EL
  MALEFICIO"). Es puramente decorativo (no colisiona ni corta la partida); al
  vencer al jefe sube la dificultad y comienza un ciclo nuevo.
- **Proyectiles**: `Area2D` con colisiones y reciclado al salir de pantalla. Las
  balas aceptan una `direction` (abanico del jefe, puntería de las navecitas y
  abanico del arma mejorada).
- **Mejoras (power-ups)**: al destruir enemigos pueden soltar un objeto
  (`PowerUp`) que cae y se recoge al tocarlo. Tipos: **arma** (nivel 1→3; abre el
  disparo en 1, 2 o 3 balas), **escudo** (absorbe un impacto, con aro visual) y
  **bomba** (se acumula hasta 3 y, al usarla con `B`/`Espacio` o el botón
  **BOMB**, limpia las balas enemigas y daña a todos los enemigos en pantalla).
  Al perder una vida se reinician el arma y el escudo (las bombas se conservan).

### Capas de colisión

| Capa | Nombre | Uso |
|---|---|---|
| 1 | `player` | Nave del jugador (cuerpo) |
| 2 | `enemy` | Enemigos |
| 3 | `player_bullet` | Disparos del jugador |
| 4 | `enemy_bullet` | Disparos enemigos |
| 5 | `powerup` | Objetos recogibles (mejoras) |
| 6 | `obstacle` | Reservado (FASE 2) |

## Arte (provisional, original)

No se usan recursos de terceros. Las naves, enemigos, proyectiles, explosiones y
el fondo estelar son **originales** y se generan por código:

- `SpriteFactory` construye texturas de pixel art a partir de mapas ASCII y una
  paleta de colores (`Image` + `ImageTexture`).
- Los jefes usan PNG con transparencia real: `assets/sprites/bosses/boss_juampi_evil.png`,
  `boss_juampi_angel.png` (el ángel del alma liberada) y `boss_infe.png`. Provienen
  de los stickers originales de `source/*.webp` (WebP que Godot no decodifica), que
  se convirtieron con Pillow:
  `python -c "from PIL import Image; Image.open('x.webp').convert('RGBA').save('x.png')"`.
  `boss_01_sprite.png` y `serial_te.png` fueron los jefes anteriores y quedan como
  arte histórico sin uso. El material original se guarda en `source/`, que Godot
  ignora (`.gdignore`) porque sus WebP no son importables.
- `starfield.gd` y `explosion.gd` dibujan fondo y explosiones con `_draw()`
  (compatible con el renderizador *Compatibility*).

Estos recursos son **provisionales**: pueden sustituirse por PNG definitivos sin
cambiar la lógica (basta asignar otra `Texture2D` al `Sprite2D` correspondiente).

## Pruebas automatizadas

El juego expone un arnés de pruebas (`tests/test_harness.gd`) que **sólo** se
activa con argumentos de línea de comandos. No afecta la partida normal.

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 `
  -Godot "C:\ruta\a\godot.exe"
```

Casos cubiertos (12): arranque + gameplay (oleadas, puntuación, colisiones, daño),
condición de derrota + reinicio, persistencia del récord, pausa, daño de los
enemigos (weaver/grunt/sniper resisten 2 impactos; diver y navecita mueren de 1,
y todos se desplazan), jefe (aparece al completar el ciclo, barra de vida, sube la
dificultad y arranca un ciclo nuevo), navecitas (el jefe las lanza, apuntan al
jugador y mueren de 1 impacto), ciclos (jefe cada 10 oleadas, dificultad
creciente y navecitas centradas), enemigos/patrones nuevos (diver y sniper; las
10 formaciones generan oleadas válidas), mejoras (arma de más balas, escudo que
absorbe un golpe, bomba que limpia balas y daña enemigos, y recogida por
colisión), audio (SFX sintetizados, música en bucle y silencio) y pantalla de
inicio con selección de dificultad (normal/difícil).

El arnés tiene además dos utilidades que no son pruebas (se invocan sin
`--headless`, con ventana):

```powershell
# 12 capturas para la ficha de Google Play → build/screenshots/
godot --path <proyecto> -- make_screenshots

# comprobar que los sprites de los jefes cargan (import válido)
godot --path <proyecto> --headless --script res://tools/check_textures.gd
```

## Android

- Resolución base 360×640 con `stretch/mode = canvas_items` y
  `stretch/aspect = expand` (pantallas altas 20:9+ sin barras negras; todo el
  código usa coordenadas relativas al viewport, nada hardcodeado a 360×640).
- Orientación vertical (`display/window/handheld/orientation = 1`).
- Límite de 60 FPS (`run/max_fps = 60`) para batería y temperatura en dispositivo.
- Controles táctiles: arrastre multi-dedo (un dedo controla la nave; un segundo
  dedo no lo cancela) y botones en pantalla **BOMB** y **PAUSA** (Android no tiene
  tecla Esc). Las capas `Dim` de los paneles usan `mouse_filter = ignore` para no
  absorber los toques de reinicio/reanudación.
- Renderizador móvil forzado a `gl_compatibility`.
- Compresión de texturas `ETC2/ASTC` habilitada (`import_etc2_astc=true`), requisito
  de la exportación a Android.
- Sin plugins ni SDK de terceros todavía (ver FASE 4/5 en `ROADMAP.md`).

### Compilar el APK (debug)

Con las plantillas de exportación, un JDK 17 y el SDK de Android configurados en
los ajustes del editor (`Android SDK Path` y `Java SDK Path`):

```powershell
# una vez, tras agregar scripts/recursos:
godot --path <proyecto> --headless --import

New-Item -ItemType Directory -Force build | Out-Null
godot --path <proyecto> --headless --export-debug "Android" `
  "<proyecto>\build\alonso-invader.apk"
```

El APK queda firmado con el *debug keystore* y listo para instalar:

```powershell
$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe install -r build\alonso-invader.apk
```

- **Paquete:** `com.alonso.invader` · **Nombre:** Alonso Invader · versionCode 1 / versionName 1.0.
- **ABI:** `arm64-v8a` (teléfonos modernos). Para equipos de 32 bits activar
  `architectures/armeabi-v7a` en `export_presets.cfg`.
- **APK de release:** `build/alonso-invader-release.apk` (firmado con el keystore
  propio v2; requiere desinstalar el APK de debug antes de instalarlo, porque la
  firma es distinta). Procedimiento completo en `SIGNING.md`.
- **AAB para Play:** `build/alonso-invader.aab` (preset "Android AAB" con Gradle).
  Falta la cuenta de Google Play Developer para subirlo (FASE 6).
- **Capturas de tienda:** `build/screenshots/` (8 de celular 1080×1920, 2 de tablet
  1600×2560, 2 de reloj 450×450), generadas por el arnés.
- **Ficha de Play:** textos, formularios (seguridad de datos, IARC) y política de
  privacidad listos en `PLAY_STORE.md` y `PRIVACY_POLICY.md`.

## Limitaciones conocidas

- **Balance provisional**: cadencia de disparo enemigo base reducida (grunt 4.6 s,
  weaver 3.6 s); grunt, weaver y sniper resisten 2 impactos (diver y navecita
  mueren de 1). El jefe aparece cada 10
  oleadas (vida base 50, cadencia 2.2 s) y lanza navecitas cada 4 s; todo escala
  con el ciclo pero está sin afinar del todo (FASE 3).
- **Modo infinito, sin pantalla de victoria**: por pedido del usuario la partida
  no termina al vencer al jefe; sube la dificultad y sigue. `HUD.show_victory` y
  el estado `VICTORY` quedan reservados por si se quiere reactivar.
- **Drops de mejoras**: probabilidad base 12 % por baja, con garantía tras 14
  bajas sin objeto (para que siempre aparezcan). Ajustable en `main.gd`
  (`DROP_CHANCE`, `DROP_PITY`).
- **APK debug generado** (2026-10-17) y probado en el celular (instalación manual
  por WhatsApp, sin `adb`): `build/alonso-invader.apk`, con copia en el escritorio
  como `AlonsoInvader.apk`. Pendiente: que el usuario valide en el dispositivo los
  jefes nuevos y la escena del alma liberada.
- Arte provisional por código para naves y enemigos; los jefes ya son PNG con
  transparencia real (reemplazables por otros de mayor resolución).
