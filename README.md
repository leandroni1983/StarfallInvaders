# Alonso Invader

Shoot 'em up vertical arcade 2D ambientado en el espacio. Proyecto original en
**Godot 4** (GDScript tipado), pensado para Android en orientación vertical y
también jugable en PC.

> Estado: **FASE 3 (progresión) completada.** Ver `ROADMAP.md`.

- **Nombre del juego:** Alonso Invader
- **Paquete Android:** `com.alonso.invader`
- **Carpeta del repositorio:** `StarfallInvaders`
- **Motor:** Godot 4.7 (GDScript tipado, sin plugins)
- **Plataformas:** Android (vertical) · Windows/PC (ventana)

## Índice

1. [Requisitos](#requisitos)
2. [Cómo ejecutar](#cómo-ejecutar)
3. [Controles](#controles)
4. [Bucle de juego](#bucle-de-juego)
5. [Enemigos](#enemigos)
6. [Jefes](#jefes)
7. [Mejoras (power-ups)](#mejoras-power-ups)
8. [Estructura del proyecto](#estructura-del-proyecto)
9. [Arquitectura](#arquitectura-resumen)
10. [Arte](#arte-provisional-original)
11. [Audio](#audio)
12. [Persistencia](#persistencia-y-récord)
13. [Pruebas automatizadas](#pruebas-automatizadas)
14. [Android](#android)
15. [Herramientas internas](#herramientas-internas)
16. [Limitaciones conocidas](#limitaciones-conocidas)
17. [Preguntas frecuentes](#preguntas-frecuentes)
18. [Historial de cambios](#historial-de-cambios)

## Requisitos

- **Godot 4.7** (probado con `4.7.2.stable.official`). Compatible con Godot 4.x.
- Renderizador: **Compatibility** (OpenGL 3.3). No requiere Vulkan.
- Para compilar en Android: plantillas de exportación de Godot, **JDK 17** y el
  **Android SDK** configurados en los ajustes del editor.

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

### Modo difícil

La pantalla de inicio permite elegir **Normal** o **Difícil**; el modo se guarda
en `SaveManager` y multiplica la vida de los enemigos/jefes (×1.3 en jefes) y la
agresividad del spawn.

## Controles

| Acción | Táctil (Android) | PC |
|---|---|---|
| Mover nave | Arrastrar el dedo | Flechas o `WASD` |
| Disparar | Automático | Automático |
| Lanzar bomba | Botón **BOMB** en pantalla | `B` o `Espacio` |
| Empezar / reiniciar | Tocar la pantalla | `Enter` o clic |
| Pausa | Botón **PAUSA** en pantalla | `Esc` |

El disparo es automático mientras se juega, como es habitual en el género. El
arrastre es **multi-dedo**: un dedo controla la nave y un segundo dedo no la
cancela (útil para pulsar BOMB/PAUSA sin soltar el movimiento).

## Bucle de juego

- **Modo infinito**: la partida no termina al vencer a un jefe. Cada ciclo tiene
  `WAVES_PER_CYCLE` (10) oleadas y termina con un jefe; al vencerlo sube la
  dificultad (`_cycle += 1`) y arranca un ciclo nuevo.
- **Formaciones de oleada**: cada oleada del ciclo usa un patrón distinto
  (fila, V, flujo lateral, pinza, francotiradores, mezclas y enjambre de cierre).
- **Puntuación y vidas**: cada baja suma puntos; el jugador pierde al ser
  alcanzado. Al perder una vida se reinician el arma y el escudo (las bombas se
  conservan).
- **Récord**: el mejor puntaje se guarda localmente.
- **Jefe del ciclo**: aparece tras la última oleada del ciclo, entra titilando
  con su aviso ("ADVERTENCIA" + nombre) y su frase característica.

## Enemigos

Todos derivan de `EnemyBase` (`Area2D`): vida, cadencia de disparo, patrón y
muerte centralizados.

| Enemigo | Script | Comportamiento | Vida |
|---|---|---|---|
| **Grunt** | `enemy_type1.gd` | desciende con vaivén lateral | 2 |
| **Weaver** | `enemy_type2.gd` | vaivén senoidal marcado | 2 |
| **Navecita** | `enemy_minion.gd` | rápida y frágil; zigzag y dispara apuntando al jugador | 1 |
| **Diver** | `enemy_diver.gd` | kamikaze; corrige el rumbo hacia el jugador | 1 |
| **Sniper** | `enemy_sniper.gd` | baja, se detiene a apuntar y dispara al jugador | 2 |

## Jefes

Los tres jefes derivan de `EnemyBase` y comparten estructura (`Sprite2D`,
`FirePoint`, `ShootTimer`, `MinionTimer`, `CollisionShape2D`), pero cada uno tiene
su propio patrón. `main.gd` rota entre ellos según el ciclo:

```gdscript
var boss_scene := BOSS                      # ciclo % 3 == 0
if (_cycle % 3) == 1:
    boss_scene = BOSS2
elif (_cycle % 3) == 2:
    boss_scene = BOSS3
```

| Jefe | Script / Escena | Sprite | Vida | Puntos | Cadencia | Patrón |
|---|---|---|---|---|---|---|
| **JUAMPI EVIL** | `boss_01.gd` / `boss_01.tscn` | `boss_juampi_evil.png` | 50 | 500 | 2.2 s | abanico de 5 balas |
| **SERIAL TE** | `boss_02.gd` / `boss_02.tscn` | `serial_te.png` | 60 | 700 | 1.8 s | salvas de 3 × 4 balas |
| **FAROL FAINA** | `boss_03.gd` / `boss_03.tscn` | `farol_faina.png` | 70 | 800 | 1.6 s | abanico de 6 balas |

### Frases de entrada (`intro_message`)

Aparecen titilando sobre la partida al entrar el jefe:

- **JUAMPI EVIL** → `"AVERIGUEMOS CUAL ES TU PERFIL\nESTOY SEGURO QUE SOS PURO HUMO!!!"`
- **SERIAL TE** → `"VAMOS A TOMAR UN TE\nVENI VENI"`
- **FAROL FAINA** → `"LA QUIERES CON EXTRA QUESO MI AMORRRRRR JAJAJAJA"`

### Navecitas (minions)

Cada jefe lanza enjambres de **navecitas** (`EnemyMinion`) cada `minion_interval`
segundos, con `minions_per_spawn` por tanda. Las navecitas descienden en zigzag
con fase aleatoria y disparan apuntando al jugador.

**FAROL FAINA** es especial: sus navecitas son **porciones de pizza** (triángulo
con borde tostado, queso y pepperoni). El sprite lo genera `SpriteFactory`
(`pizza_slice()`), y Boss03 marca cada minion con `pizza_slice = true` antes de
añadirlo al árbol. El resto de los jefes usa la navecita verde clásica.

### Alma liberada

Si el jefe define `soul_texture_path` + `soul_message`, al morir aparece su forma
liberada (clase `BossSoul`): el sprite flotando con estrellitas y corazoncitos
dibujados con `_draw`, campanitas `angel` y un mensaje titilante. Es puramente
decorativo (no colisiona ni corta la partida).

**JUAMPI EVIL** la usa: al morir aparece el ángel (`boss_juampi_angel.png`) con
`"¡GRACIAS! ¡GRACIAS! ♥\nROMPISTE EL MALEFICIO QUE ME TENÍA POSEÍDO"`.

## Mejoras (power-ups)

Al destruir enemigos pueden soltar un objeto (`PowerUp`) que cae y se recoge al
tocarlo:

- **Arma** (`weapon`): nivel 1 → 3; abre el disparo en 1, 2 o 3 balas.
- **Escudo** (`shield`): absorbe un impacto, con aro visual.
- **Bomba** (`bomb`): se acumula hasta 3 y, al usarla, limpia las balas enemigas
  y daña a todos los enemigos en pantalla.

Probabilidad base de drop: 12 % por baja, con garantía tras 14 bajas sin objeto
(`DROP_CHANCE` y `DROP_PITY` en `main.gd`).

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
│   ├── ui/           hud.tscn, start screen, pausa
│   └── bosses/       boss_01.tscn (Juampi Evil), boss_02.tscn (Serial Te),
│                     boss_03.tscn (Farol Faina)
├── scripts/
│   ├── autoload/     GameManager, SaveManager, AudioManager, SpriteFactory
│   ├── main/         main.gd
│   ├── player/       player.gd
│   ├── enemies/      enemy_base.gd, enemy_type1.gd, enemy_type2.gd,
│   │                 enemy_minion.gd, enemy_diver.gd, enemy_sniper.gd
│   ├── bosses/       boss_01.gd, boss_02.gd, boss_03.gd, boss_soul.gd
│   ├── combat/       player_bullet.gd, enemy_bullet.gd
│   ├── items/        powerup.gd
│   ├── systems/      starfield.gd, explosion.gd
│   └── ui/           hud.gd
├── assets/
│   ├── sprites/      (naves/generados por SpriteFactory)
│   │   ├── bosses/   boss_juampi_evil.png, boss_juampi_angel.png,
│   │   │             serial_te.png, farol_faina.webp
│   │   └── ui/       title_logo.png, app_icon.png
│   ├── audio/        theme.wav/ogg, boss.wav/ogg
│   ├── backgrounds/  (reservado)
│   └── fonts/        (reservado)
├── source/           material original (webp); ignorado por Godot
├── data/             (reservado para datos de balance)
├── tools/            check_textures.gd
└── tests/            test_harness.gd, run_tests.ps1
```

> `.godot/`, `build/`, `*.apk`, `*.aab`, `export_presets.cfg` y las claves de
firma están en `.gitignore` y **no** se suben al repositorio.

## Arquitectura (resumen)

- **Autoloads**
  - `GameManager`: puntuación, vidas, señales (`score_changed`, `lives_changed`,
    `game_over`, `game_started`) y estado de partida. También guarda las
    **mejoras** de la partida en curso (`weapon_level`, `shield`, `bombs`) con sus
    señales (`weapon_changed`, `shield_changed`, `bombs_changed`).
  - `SaveManager`: persistencia local del récord y del modo en `user://save.dat`.
  - `SpriteFactory`: genera las texturas de pixel art originales en tiempo de
    ejecución (ver *Arte*).
  - `AudioManager`: sintetiza **efectos** (disparo, explosión, impacto, mejora,
    bomba, golpe de jefe, aviso, campanitas del alma liberada) y **música** en
    bucle (tema de partida y tema de jefe), sin usar archivos de audio externos.
- **Main** (`scenes/main/main.tscn`): máquina de estados
  (`START` / `PLAYING` / `GAMEOVER`), spawn de oleadas, aparición del jefe,
  pausa y limpieza. Agrupa el gameplay bajo `World` (pausable) y la UI bajo
  `HUD` (CanvasLayer).
- **Ciclos y dificultad**: la partida es **infinita**. Cada ciclo tiene 10
  oleadas y termina con un jefe (rotando entre los tres). Al vencerlo sube la
  dificultad: más enemigos, más rápidos, disparan más seguido y el jefe tiene más
  vida/velocidad y lanza más navecitas.
- **Jugador**: `CharacterBody2D` con movimiento táctil (arrastre) y teclado,
  disparo automático por `Timer` y parpadeo de invulnerabilidad tras recibir daño.
- **Enemigos**: `Area2D` reutilizables sobre `EnemyBase` (vida, patrón de disparo
  y muerte). Ver la tabla de *Enemigos*.
- **Jefes**: `Boss01` (Juampi Evil), `Boss02` (Serial Te) y `Boss03` (Farol
  Faina). Emiten `health_changed` para la barra del HUD, muestran su
  `intro_message` y lanzan navecitas. `soul_texture_path` + `soul_message` activan
  la escena del alma liberada.
- **Proyectiles**: `Area2D` con colisiones y reciclado al salir de pantalla. Las
  balas aceptan una `direction` (abanico del jefe, puntería de las navecitas y
  abanico del arma mejorada).

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
  paleta de colores (`Image` + `ImageTexture`). Ejemplos: nave del jugador,
  grunt, weaver, navecita, diver, sniper, power-ups, aro de escudo, balas y la
  **porción de pizza** (`pizza_slice()`) de las navecitas de Farol Faina.
- Los jefes usan imágenes con transparencia real:
  `assets/sprites/bosses/boss_juampi_evil.png` (Juampi Evil),
  `boss_juampi_angel.png` (el ángel del alma liberada),
  `serial_te.png` (Serial Te) y `farol_faina.png` (Farol Faina). Provienen de
  los stickers originales en `source/*.webp`, convertidos a PNG con Pillow:
  `python -c "from PIL import Image; Image.open('x.webp').convert('RGBA').save('x.png')"`.
- `boss_01_sprite.png` y `boss_infe.png` quedan como arte histórico sin uso.
  El material original vive en `source/`, que Godot ignora (`.gdignore`) porque
  sus WebP no son importables.
- `starfield.gd` y `explosion.gd` dibujan fondo y explosiones con `_draw()`
  (compatible con el renderizador *Compatibility*).

Estos recursos son **provisionales**: pueden sustituirse por PNG definitivos sin
cambiar la lógica (basta asignar otra `Texture2D` al `Sprite2D` correspondiente).

## Audio

Todo el audio es **sintetizado por código** en `AudioManager` (sin archivos
externos obligatorios):

- **SFX**: disparo, explosión, impacto, mejora, bomba, golpe de jefe, aviso y
  campanitas `angel` del alma liberada.
- **Música**: tema de partida y tema de jefe, en bucle.
- `assets/audio/theme.wav/ogg` y `boss.wav/ogg` quedan como material opcional.

## Persistencia y récord

`SaveManager` guarda en `user://save.dat`:

- el **mejor puntaje** (récord),
- el **modo de dificultad** elegido.

El archivo es local; no hay backend ni servicios externos.

## Pruebas automatizadas

El juego expone un arnés de pruebas (`tests/test_harness.gd`) que **sólo** se
activa con argumentos de línea de comandos. No afecta la partida normal.

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 `
  -Godot "C:\ruta\a\godot.exe"
```

Casos cubiertos (12):

1. arranque + gameplay (oleadas, puntuación, colisiones, daño);
2. condición de derrota + reinicio;
3. persistencia del récord;
4. pausa;
5. daño de los enemigos (weaver/grunt/sniper resisten 2 impactos; diver y
   navecita mueren de 1, y todos se desplazan);
6. jefe (aparece al completar el ciclo, barra de vida, sube la dificultad y
   arranca un ciclo nuevo);
7. navecitas (el jefe las lanza, apuntan al jugador y mueren de 1 impacto);
8. ciclos (jefe cada 10 oleadas, dificultad creciente y navecitas centradas);
9. enemigos/patrones nuevos (diver y sniper; las 10 formaciones generan oleadas
   válidas);
10. mejoras (arma de más balas, escudo que absorbe un golpe, bomba que limpia
    balas y daña enemigos, y recogida por colisión);
11. audio (SFX sintetizados, música en bucle y silencio);
12. pantalla de inicio con selección de dificultad (normal/difícil).

## Android

- Resolución base 360×640 con `stretch/mode = canvas_items` y
  `stretch/aspect = expand` (pantallas altas 20:9+ sin barras negras; todo el
  código usa coordenadas relativas al viewport, nada hardcodeado a 360×640).
- Orientación vertical (`display/window/handheld/orientation = 1`).
- Límite de 60 FPS (`run/max_fps = 60`) para batería y temperatura en dispositivo.
- Controles táctiles: arrastre multi-dedo y botones en pantalla **BOMB** y
  **PAUSA** (Android no tiene tecla Esc). Las capas `Dim` de los paneles usan
  `mouse_filter = ignore` para no absorber los toques de reinicio/reanudación.
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

## Herramientas internas

```powershell
# 12 capturas para la ficha de Google Play → build/screenshots/
godot --path <proyecto> -- make_screenshots

# comprobar que los sprites de los jefes cargan (import válido)
godot --path <proyecto> --headless --script res://tools/check_textures.gd
```

## Limitaciones conocidas

- **Balance provisional**: cadencia de disparo enemigo base reducida (grunt 4.6 s,
  weaver 3.6 s); grunt, weaver y sniper resisten 2 impactos (diver y navecita
  mueren de 1). El jefe aparece cada 10 oleadas y lanza navecitas cada 3-4 s; todo
  escala con el ciclo pero está sin afinar del todo (FASE 3).
- **Modo infinito, sin pantalla de victoria**: por pedido del usuario la partida
  no termina al vencer a un jefe; sube la dificultad y sigue. `HUD.show_victory` y
  el estado `VICTORY` quedan reservados por si se quiere reactivar.
- **Drops de mejoras**: probabilidad base 12 % por baja, con garantía tras 14
  bajas sin objeto (para que siempre aparezcan). Ajustable en `main.gd`.
- **APK debug generado** (2026-10-17) y probado en el celular (instalación manual
  por WhatsApp, sin `adb`): `build/alonso-invader.apk`, con copia en el escritorio
  como `AlonsoInvader.apk`. Pendiente: que el usuario valide en el dispositivo los
  jefes nuevos y la escena del alma liberada.
- Arte provisional por código para naves y enemigos; los jefes ya son imágenes con
  transparencia real (reemplazables por otras de mayor resolución).

## Preguntas frecuentes

**¿Hace falta internet para jugar?**
No. Todo el juego (arte, audio y récord) es local.

**¿Hay compras o anuncios?**
No. No hay SDK de terceros, ni anuncios, ni compras integradas.

¿Qué necesito para exportar a Android?
Las plantillas de exportación de Godot, JDK 17 y el Android SDK configurados en
el editor. Ver la sección [Android](#android).

**¿Cómo agrego un jefe nuevo?**
1. Copiar `scripts/bosses/boss_03.gd` a `boss_04.gd` y ajustar `TEXTURE_PATH`,
   `boss_name` e `intro_message`.
2. Duplicar `scenes/bosses/boss_03.tscn`, apuntar el script y el sprite, y ajustar
   vida/puntos/cadencia.
3. Añadir la constante y la rotación del ciclo en `main.gd` (`_spawn_boss`).
4. Actualizar `README.md`, `ROADMAP.md`, `tools/check_textures.gd` y los tests.

## Historial de cambios

- **Renombrado de jefes y nuevas frases**
  - `BOSS02` pasa a llamarse **SERIAL TE** (sprite `serial_te.png`) con la frase
    `"VAMOS A TOMAR UN TE / VENI VENI"`.
  - **JUAMPI EVIL** (`BOSS01`) estrena la frase
    `"AVERIGUEMOS CUAL ES TU PERFIL / ESTOY SEGURO QUE SOS PURO HUMO!!!"`.
- **Nuevo jefe FAROL FAINA** (`BOSS03`, sprite `farol_faina.webp`) con la frase
  `"LA QUIERES CON EXTRA QUESO MI AMORRRRRR JAJAJAJA"` y navecitas con forma de
  **porción de pizza** (triángulo con borde tostado, queso y pepperoni).
- **Ciclo de jefes**: ahora rota entre los tres jefes (`_cycle % 3`) en vez de
  alternar entre dos.

Ver `ROADMAP.md` para el plan completo por fases.
