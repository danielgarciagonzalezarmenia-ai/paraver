# ParaVer

Deporte en vivo, sin ruido. Una app Flutter para seguir la cartelera de deportes y ver las señales dentro de la app, con los anuncios y las ventanas emergentes del proveedor bloqueados.

## Qué incluye

- Cartelera diaria agrupada por deporte y ordenada por hora.
- Eventos en directo, próximos partidos y canales 24/7.
- Búsqueda de eventos y canales.
- Favoritos guardados en el dispositivo.
- Tema oscuro, claro o automático.
- Reproductor integrado con selector de fuentes y pantalla completa.
- Carga el embed del proveedor en un WebView aislado, elimina sus scripts publicitarios y bloquea ventanas emergentes y navegaciones externas.
- Sin cuentas, sin analítica y sin permisos innecesarios.

## Requisitos

- iOS 13 o superior.
- Android 7.0 (API 24) o superior.
- Conexión a internet para cargar la cartelera y las señales.

## Instalar el IPA sin firmar (iPhone)

La compilación de iOS se genera en GitHub Actions y no está firmada. Para instalarla necesitas un Apple ID gratuito y una de estas herramientas:

### Opción A · Sideloadly (Windows)

1. Descarga `ParaVer-unsigned.ipa` desde la sección **Releases** del repositorio.
2. Descarga Sideloadly desde <https://sideloadly.io> e instala **Apple Devices** o iTunes desde apple.com. La versión de Microsoft Store no sirve.
3. Conecta el iPhone por USB, desbloquéalo y pulsa **Confiar** en el aviso del teléfono.
4. En el iPhone activa **Ajustes → Privacidad y seguridad → Modo desarrollador**, reinicia el dispositivo y confirma el modo desarrollador al arrancar.
5. Abre Sideloadly, arrastra el `.ipa`, escribe tu **Apple ID normal** (gratuito, no hace falta cuenta de desarrollador) y pulsa **Start**. Introduce el código 2FA si lo pide.
6. Ve a **Ajustes → General → VPN y gestión de dispositivos → Desarrollador de la app** y pulsa **Confiar**. Abre ParaVer.

### Opción B · AltStore

1. Instala AltServer en el PC y AltStore en el iPhone.
2. Inicia sesión con tu Apple ID en AltStore.
3. Descarga el IPA y ábrelo con AltStore, o usa **My Apps → +** y selecciona el archivo.
4. AltStore firma la app y la instala.

> Con un Apple ID gratuito la app caduca a los **7 días**, puedes firmar como máximo **3 apps** por cuenta y debes renovarla volviendo a pasar el `.ipa` por Sideloadly (conserva los datos) o usando **SideStore**. Es una limitación de Apple, no de ParaVer. **TrollStore no funciona en iOS 26/27**.

## Compilar desde el código

```bash
flutter pub get
flutter analyze
flutter test
```

Android:

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

iOS: el proyecto se compila en macOS o en GitHub Actions. El workflow `.github/workflows/build-ios.yml` ejecuta análisis, tests, `flutter build ios --release --no-codesign` y publica un `.ipa` sin firmar.

### Generar el IPA en GitHub Actions

1. Abre **Actions → Build iOS (IPA sin firmar) → Run workflow**.
2. Al terminar, descarga el artefacto **ParaVer-unsigned-ipa**.
3. Para publicarlo como Release, crea y sube un tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

El workflow adjunta `ParaVer-unsigned.ipa` a la Release del tag.

## Estructura

```text
lib/
  core/          tema, paleta y estilos por deporte
  data/          cliente HTTP, parser, documentos del embed y saneamiento
  models/        eventos, canales, favoritos y objetivos de reproducción
  state/         estado global de la app
  ui/            pantallas, widgets y navegación
  utils/         fechas, zona horaria del Reino Unido y utilidades
```

La cartelera se lee de `https://dlive.sx/`. Para reproducir, la app obtiene la página del embed, elimina los scripts de anuncios y las llamadas emergentes, y la carga dentro de un WebView con origen `dembed.st` para que el reproductor del proveedor funcione sin salir de ParaVer.

## Aviso

ParaVer no aloja ni retransmite contenido. Solo organiza enlaces públicos de terceros y muestra el reproductor del proveedor dentro de la app. Los derechos de las retransmisiones pertenecen a sus titulares. La disponibilidad de las señales puede cambiar sin previo aviso.

Proyecto personal, sin afiliación con las webs de origen ni con las competiciones mostradas.
