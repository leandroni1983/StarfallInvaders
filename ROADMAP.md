# ROADMAP — Alonso Invader

Progreso real del proyecto. Se actualiza al cerrar cada fase.

## FASE 0 — Diagnóstico del proyecto — COMPLETADA
- [x] Inspeccionar archivos existentes.
- [x] Detectar versión y estructura del proyecto Godot.
- [x] Identificar problemas de configuración.
- [x] Proponer estructura adecuada.

**Hallazgos:**
- El directorio no contenía un proyecto Godot (sólo `prompt.md`): se creó la
  estructura desde cero.
- Godot disponible: `4.7.2.stable.official.ed1daf0bf` (Windows).
- Se fijó Compatibility + 360×640 + orientación vertical (portrait).

## FASE 1 — MVP jugable — COMPLETADA
- [x] Escena principal (`scenes/main/main.tscn`).
- [x] Nave del jugador con movimiento táctil y por teclado.
- [x] Disparo automático funcional.
- [x] Dos tipos de enemigos (`grunt` con vaivén leve y `weaver` con onda ancha).
- [x] Movimiento y disparo de enemigos.
- [x] Colisiones funcionales (jugador/enemigos/proyectiles).
- [x] Sistema de vidas y puntuación.
- [x] Oleadas progresivas.
- [x] Condición de derrota y opción de volver a jugar.
- [x] Fondo espacial animado (estrellas en scroll + nebulosas).
- [x] Interfaz legible en vertical (HUD: puntuación, récord, vidas).
- [x] Guardado local del récord.
- [x] Recursos visuales pixel art originales (generados por código, provisorios).
- [x] Configuración inicial preparada para Android (sin plugins).
- [x] Pruebas automatizadas ejecutadas (gameplay, derrota/reinicio, guardado, pausa, daño).

**Verificado con:** Godot 4.7.2, renderizador Compatibility (OpenGL 3.3).
Pruebas: `tests/run_tests.ps1` (actualmente 11/11) + captura de pantalla real.

**Deuda técnica / notas:**
- Arte provisional generado por código; reemplazable por PNG.
- `AudioManager` es un stub (se completa en FASE 2).

## FASE 2 — Contenido arcade — COMPLETADA
- [x] Jefe cada 10 oleadas (`WAVES_PER_CYCLE`), con barra de vida.
- [x] El jefe lanza "navecitas" (`EnemyMinion`); ahora disparan apuntando al jugador.
- [x] Niveles/dificultad progresiva: modo infinito, la dificultad sube tras cada jefe.
- [x] Más enemigos y patrones de ataque: 5 tipos (grunt, weaver, navecita,
      diver kamikaze y sniper apuntado) + 5 formaciones de oleada (fila, V,
      flujo, pinza y enjambre).
- [x] Armas, mejoras, escudos y bombas: drops de `PowerUp` (arma 1→3, escudo
      que absorbe 1 golpe y bomba de pantalla límite 3), con botón/tecla BOMB.
- [x] Efectos de sonido y música: `AudioManager` sintetiza SFX y música en bucle
      (código), sin archivos de terceros.

**Detalle del jefe:**
- Escena `scenes/bosses/boss_01.tscn` + script `scripts/bosses/boss_01.gd`.
- Aparece al completar cada ciclo (10 oleadas), definido por `Main.WAVES_PER_CYCLE`.
- Patrón: entra desde arriba, se detiene y patrulla en horizontal disparando
  abanicos de 5 proyectiles (balas con dirección; `enemy_bullet.gd` acepta
  `direction`).
- **Navecitas**: cada 4 s (`minion_interval`) lanza 2 (`minions_per_spawn`)
  `EnemyMinion` que descienden en zigzag, **disparan apuntando al jugador**,
  mueren de 1 impacto (15 pts) y se añaden a `World/Enemies` (grupo
  `enemy_layer`).
- Vida base 50, puntos 500, cadencia 2.2 s. No muere al chocar con el jugador.
- **Al destruirlo NO termina la partida**: sube la dificultad (`_cycle += 1`,
  más enemigos/rápidos/cadencia, jefe con más vida) y empieza un ciclo nuevo.
- Sprite original de esta fase: `assets/sprites/bosses/boss_01_sprite.png`
  (PNG con transparencia real, recortado de `source/boss_01.webp`).
  **Reemplazado en FASE 3.9** por `boss_juampi_evil.png` ("JUAMPI EVIL").

**Segundo jefe (alterna por ciclo):**
- Escena `scenes/bosses/boss_02.tscn` + script `scripts/bosses/boss_02.gd` (clase
  `Boss02`).
- `Main` alterna: **jefe 1 en ciclos pares, jefe 2 en ciclos impares** (`_cycle % 2`).
- Patrón distinto: varias ráfagas seguidas en abanico (multi-volley) y navecitas
  más rápidas con cadencia propia.
- Sprite original "SERIAL TEA" (`serial_te.png`, PNG 512×512 RGBA convertido de un
  WebP mal codificado): **reemplazado en FASE 3.9** por `boss_infe.png`
  ("EL INFE", que entra con su frase titilante).

## FASE 3 — Progresión — COMPLETADA
- [x] Récords persistentes ampliados (alta compatibilidad con formato anterior +
      JSON `save.json` con `high_score` y `best_cycle`).
- [~] Desbloqueos y mejoras (preparado; sin bloqueo para continuar).
- [x] Guardado y carga seguros (detección de formato, valores por defecto, uso de
      variantes tipados).
- [x] Balance de dificultad (drops y escalado de dificultad verificados con las
      baterías de pruebas).

## FASE 3.5 — Pulido audiovisual — COMPLETADA
- [x] **Sacudón de cámara** (`Camera2D` en `World` + `GameManager.request_shake`):
      al recibir daño, al usar bomba y sobre todo al destruir un jefe. Trauma con
      caída cuadrática (`SHAKE_MAX` / `SHAKE_DECAY` en `main.gd`).
- [x] **Aviso de jefe**: banner rojo pulsante "ADVERTENCIA" + nombre del jefe antes
      de la pelea (`HUD.show_warning`), con sonido de sirena (`warning`).
- [x] **Música de jefe** distinta (más rápida y tensa) que cambia al aparecer el
      jefe y vuelve al tema normal al destruirlo (`AudioManager.play_music("boss"/"theme")`).
- [x] **Destrucción de jefe**: explosión grande (`big_explosion`) + anillo de
      explosiones en expansión (`Main._spawn_death_burst`) + flash y sacudón fuerte.
- [x] **Fondo variable por ciclo**: planeta lejano con anillo y nebulosa que cambian
      de color/posición al subir de nivel (`Starfield.set_cycle`).
- [x] **Indicador de combo**: rachas de bajas encadenadas dentro de una ventana
      (`COMBO_WINDOW`) con puntos extra; HUD `ComboLabel` que se enciende y se
      apaga solo. Se corta al recibir daño.
- [x] **Chispas de impacto**: al dañar (sin destruir) un enemigo aparece un pequeño
      fogonazo dorado, además del flash blanco del sprite.

## FASE 3.6 — Pantalla de inicio y dificultad — COMPLETADA
- [x] **Menú de inicio real** (no sólo texto): título, subtítulo, récord y selección
      de dificultad con dos botones (mouse/táctil) y navegación por teclado
      (←/→/↑/↓ cambia la opción, Enter empieza). Panel `HUD/StartPanel`.
- [x] **Dificultades** `GameManager.Difficulty`:
      - **NORMAL**: 3 vidas, valores clásicos.
      - **DIFÍCIL**: 2 vidas, enemigos 1,35× más rápidos, disparan más seguido
        (×0,75 de intervalo), +1 de vida por enemigo, menos drops (×0,7) y
        **puntaje ×1,5**.
- [x] La dificultad elegida se aplica a oleadas, jefes y drops, y se muestra en la
      pantalla de game over.
- [x] Prueba automática nueva (`test_difficulty`): 12/12 pruebas en verde.

## FASE 3.7 — Arte gráfico: logo e icono — COMPLETADA
- [x] **Logo tipográfico original** para el menú de inicio
      (`assets/sprites/ui/title_logo.png`, 356×174): fuente de mapa de bits 5×7
      propia dibujada en `tools/gen_title_logo.py`, con degradado cromado
      cian→azul, bisel claro/oscuro, contorno, resplandor, sombra y destellos.
      Sustituye al título en texto plano en `HUD/StartPanel/TitleLogo`.
- [x] **Icono de la app** (`assets/sprites/ui/app_icon.png`, 512×512): misma
      tipografía (letra "A" cromada) sobre fondo espacial redondeado con
      estrellas y filete dorado. Se usa como `config/icon` y como icono de
      lanzador de Android (reemplaza al icono por defecto de Godot).
- [x] El generador queda en `tools/gen_title_logo.py` (excluido de la exportación)
      para poder regenerar el arte sin dependencias de terceros.

## FASE 3.8 — Música heavy metal — COMPLETADA
- [x] **Tema musical reescrito con onda heavy metal** (`AudioManager`): riff de
      palm mute en galope sobre acordes de quinta distorsionados (E5–C5–G5–D5 en
      Mi menor), saturación tipo amplificador de válvulas (diente de sierra +
      `tanh`), filtro paso-bajo suave, bajo grave en cada tiempo, batería
      sintetizada (bombo, caja y charles) y melodía solista en Mi menor.
- [x] **Música de jefe** con la misma base pero más rápida (174 BPM) y doble
      bombo a 16avos, para más agresividad en la pelea.
- [x] Bucle sin cortes (12,0 s de tema a 160 BPM); todo generado por código, sin
      samples de terceros.
- [x] `test_audio` sigue en verde; batería completa 12/12 sin errores de script.

## FASE 3.9 — Jefes con personalidad — COMPLETADA
- [x] **Jefe 1 "JUAMPI EVIL"** (`boss_01.gd`, sprite `boss_juampi_evil.png`): al
      morir se rompe el maleficio y aparece su forma liberada, el **ángel**
      (`scripts/bosses/boss_soul.gd`, sprite `boss_juampi_angel.png`): flota con
      un halo que respira, rodeado de **estrellitas doradas y corazoncitos
      rosas** (dibujados con `_draw()`, sin assets), mientras el HUD titila
      "¡GRACIAS! ¡GRACIAS! ♥ / ROMPISTE EL MALEFICIO / QUE ME TENÍA POSEÍDO".
      Es puramente decorativo: no colisiona, no cuenta como enemigo y la partida
      sigue (sube el ciclo y arranca un nivel nuevo).
- [x] **Jefe 2 "EL INFE"** (`boss_02.gd`, sprite `boss_infe.png`): al entrar lanza
      su frase titilante "DAME MI PERUANITA / AH AH AH".
- [x] Sistema de mensajes del HUD (`HUD.show_message`): texto centrado que titila
      sobre la partida sin bloquearla, por encima de los paneles y del telón.
- [x] Los tres stickers nuevos venían en WebP que Godot **no decodifica**; se
      convirtieron a PNG con Pillow y los originales quedaron en `source/`
      (ignorado por Godot). Herramienta nueva `tools/check_textures.gd` para
      verificar que los sprites cargan de verdad.
- [x] Efecto de sonido propio para la liberación (`angel`): campanitas
      celestiales ascendentes sintetizadas por `AudioManager` (armónicos +
      vibrato), sumadas a `test_audio`.

## FASE 4 — Android — EN CURSO
- [x] Configuración de exportación (JDK 17, SDK Android, plantillas 4.7.2, ETC2/ASTC).
- [x] **APK debug** generado y validado (`build/alonso-invader.apk`,
      paquete `com.alonso.invader`, `arm64-v8a`).
- [x] **Firma de release (keystore propio)**: keystore PKCS12 **v2** en
      `C:\Users\Leandro\AndroidTools\alonso-invader-release-v2.keystore` (alias
      `alonso`, guardado fuera del repo; el keystore original se rotó el 17/10
      porque se perdió su contraseña y la app todavía no estaba publicada) y
      **APK de release firmado** (`build/alonso-invader-release.apk`) verificado
      con `apksigner`. Procedimiento documentado en `SIGNING.md`.
- [x] Ajustar controles y escalado en dispositivo (hecho en código; validación
      física pendiente junto al punto siguiente).
- [ ] Probar en dispositivo físico (instalación manual del APK: no hay `adb`
      disponible — se pasa por WhatsApp y se instala desde el celular).
- [ ] Corregir rendimiento y orientación (base hecha: `max_fps = 60`, orientación
      portrait forzada; falta perfilar en el dispositivo real).
- [x] **AAB generado** (`build/alonso-invader.aab`, preset "Android AAB" con
      Gradle, firmado con el keystore v2) — falta subirlo a Play Console.
- [ ] Publicar en Play Console (Play App Signing) subiendo el AAB.

**Avances 17/10 (software, sin dispositivo físico):**
- Escalado: `stretch/aspect = expand` (sin letterbox en pantallas 20:9+); todas
  las coordenadas fijas 360×640 del código reemplazadas por valores relativos al
  viewport (juego, enemigos, proyectiles, mejoras, patrones de oleada y jefes);
  cámara y starfield se ajustan al redimensionar.
- Controles: botón **PAUSA** en pantalla (Android no tiene Esc), arrastre
  multi-dedo con dedo asignado (un segundo dedo no cancela el control de la
  nave) y capas `Dim` de los paneles en `mouse_filter = ignore` —antes `STOP`,
  absorbían los toques e impedían reiniciar tras el game over o reanudar la
  pausa en táctil—.
- Rendimiento: `run/max_fps = 60`.
- Batería de pruebas 12/12 en verde. Se verificó el balance real de enemigos
  (weaver/grunt/sniper: **2 impactos**; diver/navecita: 1) y se actualizaron
  arnés, README y `run_tests.ps1` para que lo reflejen; además se corrigieron
  3 bugs del arnés (aislamiento del récord en `test_save`, captura síncrona de
   balas en `test_minions`/`test_enemies` y espera de 2 impactos en el sniper).
- Jefes nuevos con personalidad (ver FASE 3.9); batería 12/12 verde tras el cambio.
- Artefactos firmados con el keystore v2: `build/alonso-invader.apk` (debug, misma
  firma que el anterior → actualiza sin desinstalar), `build/alonso-invader-release.apk`
  y `build/alonso-invader.aab` para Play. Se agregó `build/*` al `exclude_filter`
  para que los artefactos y las capturas no viajen dentro del paquete.
- 12 capturas de tienda generadas en `build/screenshots/` con el escenario
  `make_screenshots` del arnés (menú, juego, mejoras, aviso y pelea del jefe,
  navecitas, alma liberada y game over).

## FASE 5 — Monetización — PENDIENTE (posterior a la publicación)
> **Decisión 17/10:** se publica primero **sin anuncios** (menos riesgo de
> rechazo en la primera revisión de Play) y AdMob se agrega después como
> actualización. Mientras tanto la fase queda en pausa.
- [ ] Seleccionar e integrar complemento AdMob compatible.
- [ ] Configurar anuncios de prueba.
- [ ] Consentimiento y privacidad.
- [ ] Probar recompensas y frecuencia.

## FASE 6 — Publicación — EN CURSO
- [x] Material de ficha de Play preparado (`PLAY_STORE.md`: textos, formularios,
      respuestas guía de IARC y seguridad de datos) y `PRIVACY_POLICY.md`.
- [x] AAB: preset "Android AAB" con Gradle **exportado y firmado** con el
      keystore v2 (`build/alonso-invader.aab`).
- [ ] **Cuenta de Google Play Developer** (USD 25 + identidad) — pendiente del
      usuario; sin esto no se publica.
- [x] Generar las 12 capturas obligatorias (8 celular 1080×1920, 2 tablet
      1600×2560, 2 reloj 450×450) en `build/screenshots/` con el generador
      `make_screenshots` del arnés.
- [ ] Subir AAB a prueba cerrada, completar ficha y pasar a producción.
- [ ] Verificación de requisitos de Google Play.
