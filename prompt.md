# PROYECTO: STARFALL ARCADE

## 1. Rol y objetivo

Actuá como un desarrollador senior de videojuegos especializado en Godot 4, GDScript, juegos arcade 2D, pixel art y exportación para Android.

Tu objetivo es desarrollar un videojuego comercial completo, estable y publicable en Google Play Store, inspirado en los clásicos shoot 'em up verticales de los años 80 y 90, como 1942, pero ambientado en el espacio y con identidad visual, nombres, personajes y recursos originales.

El nombre provisional del proyecto es **Starfall Arcade**.

No te limites a dar instrucciones: trabajá directamente sobre los archivos del proyecto, implementá las funcionalidades y verificá los resultados siempre que tus herramientas lo permitan.

## 2. Tecnología y restricciones

- Motor: Godot 4.x.
- Lenguaje: GDScript tipado, siguiendo las convenciones de Godot.
- Género: arcade shoot 'em up con desplazamiento vertical.
- Plataforma principal: Android.
- Orientación: vertical (portrait).
- Controles: táctiles, con posibilidad de probar el juego en PC.
- Renderizado: Compatibility.
- Arte: pixel art original inspirado en las recreativas de 8 y 16 bits.
- Resolución de diseño inicial: 360 × 640, con escalado correcto a distintas pantallas.
- Proyecto autocontenido, sin servidor ni backend para la primera versión.
- Guardado local de puntuación, récords y progreso.
- No incorporar dependencias externas innecesarias.
- No usar recursos con licencias desconocidas ni copiar assets, nombres o música de otros juegos.

Antes de modificar archivos, inspeccioná el proyecto existente y conservá todo lo que sea válido. No sobrescribas ni elimines archivos del usuario sin comprobar su contenido.

Si el directorio no contiene un proyecto Godot válido, informá el problema antes de crear una estructura nueva.

## 3. Concepto jugable

El jugador controla una nave espacial que avanza por una zona hostil mientras destruye formaciones de enemigos.

Características fundamentales:

- Desplazamiento vertical del escenario.
- Nave controlable con el dedo.
- Movimiento fluido, limitado a los bordes de la pantalla.
- Disparo automático mientras se juega.
- Proyectiles del jugador y de los enemigos.
- Colisiones y daño.
- Explosiones y efectos visuales pixel art.
- Enemigos con distintos patrones de movimiento.
- Oleadas progresivas.
- Puntuación y récord.
- Vidas del jugador.
- Pantallas de inicio, pausa, derrota y victoria.
- Efectos de sonido y música, incorporados progresivamente.

El juego debe ser divertido, legible en pantallas pequeñas y funcionar con una tasa de fotogramas estable.

## 4. Dirección artística

Diseñá una identidad visual propia:

- Naves con siluetas reconocibles.
- Paleta limitada de colores.
- Fondo espacial con estrellas en movimiento.
- Planetas, nebulosas y asteroides.
- Proyectiles diferenciados por color y forma.
- Explosiones breves y legibles.
- Interfaz arcade con tipografía pixelada.
- Efectos de daño y destrucción visibles.

Usá recursos originales creados mediante formas, polígonos, shaders sencillos o sprites propios. No uses rectángulos de colores como solución artística definitiva.

Si no hay herramientas de generación de imágenes disponibles, creá recursos provisionales mediante código y dejá clara su condición temporal.

## 5. Arquitectura inicial

Mantené una estructura modular y fácil de ampliar. Como referencia:

res://
- project.godot
- scenes/
  - main/
  - player/
  - enemies/
  - projectiles/
  - effects/
  - ui/
  - levels/
  - bosses/
- scripts/
  - autoload/
  - player/
  - enemies/
  - combat/
  - systems/
  - ui/
- assets/
  - sprites/
  - backgrounds/
  - audio/
  - fonts/
- data/
- tests/
- README.md

Adaptá esta estructura cuando exista una razón técnica concreta. No crees archivos vacíos sin utilidad.

Separá las responsabilidades de jugador, enemigos, proyectiles, niveles, interfaz, audio y guardado.

Usá señales de Godot para comunicar eventos cuando corresponda. Evitá dependencias circulares y lógica duplicada.

Definí las capas y máscaras de colisión de forma coherente. Usá escenas reutilizables y parámetros exportados para facilitar el balance del juego.

No agregues un sistema complejo de gestión de estados si una solución sencilla y robusta es suficiente.

## 6. Primera versión jugable

El primer entregable debe ser un MVP jugable, no un menú vacío ni una colección de scripts sin integrar.

Debe incluir:

1. Una escena principal que ejecute el juego.
2. Una nave del jugador con movimiento táctil y control mediante teclado para pruebas en PC.
3. Disparo automático funcional.
4. Al menos dos tipos de enemigos.
5. Movimiento y disparo de enemigos.
6. Colisiones funcionales.
7. Sistema de vidas y puntuación.
8. Una oleada de enemigos.
9. Una condición de derrota y opción de volver a jugar.
10. Un fondo espacial animado.
11. Una interfaz legible en orientación vertical.
12. Guardado local del récord.
13. Recursos visuales coherentes con el estilo pixel art.
14. Una configuración inicial preparada para Android.

La primera versión debe poder ejecutarse desde el editor de Godot sin errores ni dependencias inexistentes.

## 7. Calidad y buenas prácticas

- Usá tipado estático en GDScript siempre que resulte práctico.
- Evitá código duplicado y variables globales innecesarias.
- Liberá correctamente los nodos y proyectiles que ya no se utilizan.
- Evitá crear cantidades ilimitadas de nodos en cada fotograma.
- Gestioná correctamente las pausas y el reinicio de la partida.
- Validá referencias a nodos y recursos.
- No ocultes errores mediante bloques de excepciones generales.
- No afirmes que una funcionalidad está probada si no la ejecutaste.
- Ejecutá las verificaciones disponibles y corregí los errores que encuentres.
- No cambies configuraciones ajenas al juego sin una razón concreta.

## 8. Android y monetización futura

Prepará el proyecto para exportación a Android, pero no integres todavía SDK de publicidad ni complementos de terceros.

En fases posteriores se incorporará Google AdMob mediante un complemento compatible con la versión elegida de Godot.

La monetización prevista incluye:

- Publicidad discreta en menús.
- Anuncios recompensados opcionales para continuar una partida o conseguir recompensas.
- Anuncios intersticiales limitados a transiciones naturales.

Nunca mostrar anuncios durante el combate ni bloquear los controles.

No incluyas identificadores reales de publicidad, claves ni credenciales en el repositorio. Durante el desarrollo se utilizarán identificadores de prueba oficiales.

## 9. Reglas de trabajo

Trabajá por fases y mantené un archivo `ROADMAP.md` con el progreso real.

FASE 0 — Diagnóstico del proyecto:
- Inspeccionar los archivos existentes.
- Detectar la versión y estructura del proyecto Godot.
- Identificar problemas de configuración.
- Proponer una estructura adecuada.

FASE 1 — MVP jugable:
- Crear la escena principal.
- Implementar nave, movimiento, disparos, enemigos, colisiones, vidas y puntuación.
- Incorporar el fondo animado y la interfaz.
- Verificar el funcionamiento desde Godot.

FASE 2 — Contenido arcade:
- Añadir nuevos enemigos y patrones.
- Implementar niveles, dificultad progresiva y jefes.
- Incorporar armas, mejoras, escudos y bombas.
- Añadir efectos de sonido y música.

FASE 3 — Progresión:
- Récords persistentes.
- Desbloqueos y mejoras.
- Guardado y carga seguros.
- Balance de dificultad.

FASE 4 — Android:
- Ajustar controles y escalado.
- Configurar exportación y firma.
- Probar en un dispositivo físico.
- Corregir problemas de rendimiento y orientación.

FASE 5 — Monetización:
- Seleccionar e integrar un complemento compatible con AdMob.
- Configurar anuncios de prueba.
- Verificar consentimiento y requisitos de privacidad aplicables.
- Probar recompensas y frecuencia de anuncios.

FASE 6 — Publicación:
- Icono, capturas, descripción y ficha de Play Store.
- Pruebas de lanzamiento.
- Generación del Android App Bundle (AAB).
- Verificación de los requisitos vigentes de Google Play.

No intentes implementar todas las fases en una sola operación.

## 10. Instrucción inmediata

Comenzá ahora por la FASE 0.

Inspeccioná el directorio de trabajo y confirmá la versión de Godot disponible si podés acceder a ella.

Después implementá la FASE 1 completa, priorizando una versión pequeña pero realmente jugable.

Trabajá directamente sobre los archivos, ejecutá las verificaciones disponibles y corregí los errores.

Al finalizar, informá:

- Archivos creados y modificados.
- Funcionalidades implementadas.
- Comandos o pasos exactos para ejecutar el juego.
- Pruebas ejecutadas y sus resultados reales.
- Errores pendientes y limitaciones.
- Próximo paso recomendado.

No afirmes que Android o AdMob están listos hasta haberlos verificado específicamente.

Si necesitás tomar decisiones menores, elegí la alternativa más simple y mantenible. Si encontrás un bloqueo que impide continuar, explicá el problema concreto en lugar de inventar una solución.
