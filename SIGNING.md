# Firma y distribución — Alonso Invader

Guía para firmar el juego y publicarlo. Todo está pensado para **no** meter
claves ni contraseñas dentro del repositorio.

## Datos de la firma

| Dato | Valor |
| --- | --- |
| Paquete (applicationId) | `com.alonso.invader` |
| Keystore de release | `C:\Users\Leandro\AndroidTools\alonso-invader-release-v2.keystore` |
| Alias de la clave | `alonso` |
| Contraseña | *(en el gestor de contraseñas del usuario; rotada el 17/10/2026)* |
| Tipo | PKCS12, RSA 2048 bits, validez 10 000 días |
| Huella SHA-256 | `64:DE:51:BB:1D:4E:4D:18:EC:37:29:66:A8:95:7F:30:4F:33:86:EF:2D:3E:5E:07:9C:6A:A0:75:E7:B0:85:55` |

> **Rotación 17/10/2026**: se perdió la contraseña del keystore original
> (`alonso-invader-release.keystore`, huella `B6:56:65:…`). Como la app
> **nunca llegó a publicarse** en Play, se creó este keystore **v2** sin
> consecuencias. El archivo viejo quedó en su lugar como reserva histórica;
> no usarlo. **Guardá esta contraseña en el gestor: es la definitiva** — si se
> pierde de nuevo y la app ya está publicada, no se podrá enviar ninguna
> actualización.

> ⚠️ **El keystore vive FUERA del proyecto** (en `AndroidTools`) y nunca debe
> subirse a git. Ya está en `.gitignore` (`*.keystore`, `*.jks`, `*.p12`,
> `export_credentials.cfg`). **Si perdés el keystore, no podés volver a
> actualizar la app.** Respaldalo en un pendrive + gestor de contraseñas.

## Herramientas (rutas de esta máquina)

- **Godot**: `C:\Users\Leandro\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- **JDK 17**: `C:\Users\Leandro\AndroidTools\jdk-17.0.20.1+1`
  - `keytool`: `...\jdk-17.0.20.1+1\bin\keytool.exe`
- **Android SDK**: `C:\Users\Leandro\AppData\Local\Android\Sdk`
  - `apksigner`: `...\Sdk\build-tools\36.0.0\apksigner.bat`

Estas rutas ya están configuradas en *Editor Settings → Export → Android*.

## 1) Crear el keystore (hecho; v2 desde el 17/10/2026)

```powershell
& "C:\Users\Leandro\AndroidTools\jdk-17.0.20.1+1\bin\keytool.exe" -genkeypair -v `
  -keystore "C:\Users\Leandro\AndroidTools\alonso-invader-release-v2.keystore" `
  -alias alonso -keyalg RSA -keysize 2048 -validity 10000 `
  -storetype PKCS12 -storepass <PASS> -keypass <PASS> `
  -dname "CN=Alonso Invader, OU=Games, O=Alonso, C=AR"
```

> En PKCS12 la contraseña del keystore y de la clave **deben ser la misma**.

## 2) Exportar el APK firmado (para compartir / instalar directo)

No usa Gradle: es rápido. El resultado queda en `build/alonso-invader-release.apk`.

```powershell
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH   = "C:\Users\Leandro\AndroidTools\alonso-invader-release-v2.keystore"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER   = "alonso"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "<PASS>"

& "<godot>" --headless --path "C:\Users\Leandro\Desktop\StarfallInvaders" `
  --export-release "Android" "build/alonso-invader-release.apk"
```

(`--export-release` = sin debug. `--export-debug` genera un APK de prueba.)

## 3) Exportar el AAB (para Google Play)

Play exige un **AAB** desde agosto de 2021. Eso requiere **Gradle build**:

- Preset creado: **"Android AAB"** (`gradle_build/use_gradle_build=true`,
  `gradle_build/export_format=1`).
- La plantilla Android ya está instalada en `res://android/build`.
- Requisitos del toolchain (según el propio template): compileSdk **36**,
  build-tools **36.1.0**, NDK **29.0.14206865**, AGP 8.6.1, Java 17.

```powershell
& "<godot>" --headless --path "C:\Users\Leandro\Desktop\StarfallInvaders" `
  --export-release "Android AAB" "build/alonso-invader.aab"
```

En Play Console usá **Google Play App Signing**: subís el AAB firmado con tu
*clave de subida* (el keystore de arriba) y Google firma con la clave de app.

## 4) Verificar la firma de un artefacto

```powershell
$env:JAVA_HOME = "C:\Users\Leandro\AndroidTools\jdk-17.0.20.1+1"
& "C:\Users\Leandro\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat" `
  verify --print-certs "build\alonso-invader-release.apk"
```

Debe mostrar el DN `CN=Alonso Invader, OU=Games, O=Alonso, C=AR` y la huella
SHA-256 de arriba.

## 5) Publicar actualizaciones

1. Incrementá `version/code` (y `version/name`) en `export_presets.cfg` en cada
   release; si no, Play rechaza la subida.
2. Volvé a exportar y subí el AAB.
3. **Usá siempre el mismo keystore.** Con otro, Android rechaza la instalación
   sobre la versión anterior.

## Canales de distribución

- **Directo:** el APK firmado por WhatsApp / Drive / itch.io, etc. (cualquiera
  puede instalarlo habilitando "orígenes desconocidos").
- **Google Play:** cuenta de desarrollador (USD 25 única vez), subís el AAB.
- **Otras tiendas:** Amazon Appstore, Samsung Galaxy Store, Huawei AppGallery.

## Reglas de oro

1. Nunca perder ni compartir el keystore ni la contraseña.
2. No commitear la clave (ya está en `.gitignore`).
3. Subir `version/code` en cada entrega.
4. `com.alonso.invader` es **permanente** una vez publicado en Play.
