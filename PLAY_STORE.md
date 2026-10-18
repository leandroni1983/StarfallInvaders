# Ficha de Google Play — Alonso Invader

Material de trabajo para cargar en Play Console cuando exista la cuenta de
desarrollador. Todo esto se generó/provisionó antes de tiempo para que la
publicación sea un trámite, no un proyecto.

## Datos técnicos del paquete

| Dato | Valor |
|------|-------|
| Paquete | `com.alonso.invader` |
| Nombre en tienda | Alonso Invader |
| Versión | versionCode 1 / versionName 1.0 |
| Orientación | Vertical (portrait), sólo |
| Dispositivos | Teléfonos (sin tablets propias; se adapta a pantallas altas 20:9+) |
| Permisos que pide | Ninguno |
| Datos que recopila | Ninguno (ver `PRIVACY_POLICY.md`) |
| AAB | `build/alonso-invader.aab` (export-release, preset "Android AAB") |
| Firma | Play App Signing (Google firma el release; el keystore propio sólo firma el upload inicial, ver `SIGNING.md`) |

## Textos de la ficha

**Título (30 máx.):** `Alonso Invader`

**Subtítulo corto (80 máx.):**
```
Shmup arcade vertical: oleadas, jefes y potenciadores. ¡Sobreviví a la invasión!
```

**Descripción completa (4000 máx.):**
```
¡La flota invasora llegó desde las estrellas y sólo tu nave puede frenarla!

ALONSO INVADER es un shoot'em up arcade vertical con partidas rápidas, controles
de un dedo y esa "una partida más" que no te deja dejar el celular.

CARACTERÍSTICAS
• Oleadas infinitas con 5 formaciones distintas (fila, V, flujo, pinza y
  enjambre) y 5 tipos de enemigos: vaivén, onda ancha, kamikaze, francotirador
  apuntado y las "navecitas" del jefe.
• Un jefe cada 10 oleadas, con barra de vida, ataques en abanico y su propio
  tema musical. Al destruirlo la dificultad sube y el ciclo continúa: el puntaje
  es infinito.
• Jefes con personalidad: JUAMPI EVIL, que al caer rompe el maleficio y deja ver
  a su ángel liberado, agradecido entre estrellitas y corazoncitos… y EL INFE,
  que entra al grito de "¡DAME MI PERUANITA, AH AH AH!".
• Mejoras que caen en combate: arma triple, escudo que absorbe un impacto y
  bomba de pantalla completa (guardá la para el momento justo).
• Racha de combos con puntos extra y récord persistente en tu dispositivo.
• Banda sonora original heavy metal, sintetizada exclusivamente para el juego.
• Dos dificultades: NORMAL (clásica, 3 vidas) y DIFÍCIL (2 vidas, enemigos más
  rápidos y resistentes, puntaje ×1,5).

CONTROLES
Arrastrá el dedo para mover la nave; dispara sola. Tocá BOMB para la bomba y II
para pausar. Todo pensado para jugar con una mano, en vertical.

¡Descargalo gratis y sobreviví a la invasión!
```

**Categoría sugerida:** Juegos → Arcade (subcategoría: Shoot'em up / Arcade de
acción).
**Clasificación por edad:** esperar el resultado del cuestionario IARC
(respuestas sugeridas abajo). Contiene violencia de dibujos animados sin sangre
ni gore → probablemente **3+ / 12+** según el país.
**Tags:** arcade, shoot em up, shmup, espacial, retro, offline, un jugador.

## Formularios de Play Console

### Seguridad de datos (Data safety)
- ¿Recopila datos? **No** — ni cuentas, ni ubicación, ni analítica, ni anuncios
  (por ahora), ni permisos del dispositivo. Las puntuaciones se guardan
  únicamente en el almacenamiento local del teléfono (`user://save.json`).
- Declarar: "No se recopilan ni se comparten datos".

### Cuestionario de clasificación de contenido (IARC)
Respuestas guía (respuesta honesta: es un arcade de naves sin gore):
- Violencia: sí, fantasía/arcade — naves que disparan a naves; explosiones
  abstractas; sin sangre, sin heridas, sin personas.
- Miedo: no. Contenido sexual: no. Lenguaje: no. Consumo de drogas: no.
  Contenido sexual o discriminatorio: no. Interacción en línea: no.
- Compras dentro de la app: no (hasta integrar AdMob/recompensas; si se agregan
  anuncios rellenar de nuevo).

### Capturas (12 obligatorias para cuentas nuevas)
- 8 de celular (1080×1920), 2 de tablet (1600×2560), 2 de reloj (450×450).
- **Generadas** en `build/screenshots/` con la escena automática del arnés:
  `godot --path <proyecto> -- make_screenshots`. Momentos del celular: menú,
  partida, mejoras, aviso del jefe, pelea del jefe, navecitas, **alma liberada**
  (el ángel con estrellitas y corazones) y game over.
- Antes de subirlas al Play Console, revisar que no muestren nada que no deba
  (por ejemplo el botón de pausa o marcadores de depuración).

## Pasos cuando exista la cuenta
1. Crear la app en Play Console → tipo "Juego" → paquete `com.alonso.invader`.
2. Subir `build/alonso-invader.aab` a **Pruebas interno/cerrado**.
3. Completar ficha (textos de arriba), seguridad de datos, IARC y capturas.
4. Aprobar la prueba cerrada (vos + hasta 100 testers con link).
5. Pasar a producción. Play App Signing firma el build final.
