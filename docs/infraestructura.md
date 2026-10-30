# Infraestructura y secretos — Kayuco

Inventario de cuentas, recursos y secretos (regla 30 del estándar). **Nunca lleva valores**: solo nombres, ubicaciones y pasos. Quien lo lea sin ayuda de nadie más debe poder entender cómo está armado el proyecto y reconstruirlo.

**Última revisión:** 2026-10-30 · **Responsable:** Eduardo

## 1. Cuentas y paneles
| Servicio | Cuenta u organización | Panel | Para qué se usa | Quién puede entrar |
|---|---|---|---|---|
| GitHub | eduardothomas | https://github.com/eduardothomas/kayuco | Código abierto, PR, CI Linux, Releases | Eduardo |
| GitHub | eduardothomas | https://github.com/eduardothomas/kayuco-apps | Apps de pago (privado) | Eduardo |
| Apple Developer / App Store Connect | cuenta personal de Eduardo | https://appstoreconnect.apple.com | Firma, TestFlight, App Store, Xcode Cloud, CloudKit | Eduardo |
| Registrador de dominios | pendiente | — | `kayuco.app` / `kayuco.dev` (pendientes de compra) | Eduardo |

Los pasos de recuperación de cada cuenta raíz están en la hoja de emergencia (en el gestor y en papel, no aquí).

## 2. Entornos y cómo probarlos
| Entorno | Rama | Host de Mac | Apps | CloudKit | Cómo probarlo |
|---|---|---|---|---|---|
| Local / dev | cualquiera | bundle `.dev`, puerto y nombre Bonjour dev | bundle `.dev` (TestFlight interno) | Development | `bash scripts/check.sh`; correr el host dev y la app dev en el mismo Wi‑Fi |
| Beta | `develop` (en `kayuco-apps`) | release candidato | TestFlight externo | Development → promovido | TestFlight |
| Producción | `main` | GitHub Releases + Homebrew (notarizado) | App Store | Production | Con autorización de Eduardo |

## 3. Recursos
IDs que no son secretos (sirven para reconstruir; no dan acceso por sí solos).

| Tipo | Nombre | ID | Entorno | Notas |
|---|---|---|---|---|
| Bundle ID | `com.kayuco.host` / `com.kayuco.host.dev` | — | prod / dev | Host y menu bar de Mac (pendiente de crear) |
| Bundle ID | `com.kayuco.app` / `com.kayuco.app.dev` | — | prod / dev | Apps iPhone/iPad/Watch, en `kayuco-apps` (pendiente) |
| Contenedor CloudKit | `iCloud.com.kayuco` | — | dev / prod | Esquema solo aditivo (ADR 0007) (pendiente) |
| Dominio | `kayuco.app`, `kayuco.dev` | — | prod | Pendientes de verificar y comprar |

## 4. Secretos
Cada nombre es igual en la copia de ejecución, en esta tabla y en la entrada del gestor. Si el proveedor lo muestra una sola vez, se guarda en el gestor en ese momento. **Ningún secreto de proveedores de IA del usuario pasa por aquí: viven solo en el Keychain del dispositivo del usuario (ADR 0005).**

| Nombre | Para qué sirve | Copia de ejecución | Entrada del gestor | Permisos | Creado | Vence | Cómo rotarlo o recrearlo |
|---|---|---|---|---|---|---|---|
| `APPLE_SIGNING` (certificados y perfiles) | Firmar host y apps | Xcode Cloud (firma administrada por Apple) | `Kayuco · Apple – firma` | solo este equipo de desarrollo | pendiente | según Apple | Revocar y regenerar en developer.apple.com; Xcode Cloud los toma solo |
| `ASC_API_KEY_KAYUCO` | Subir builds y publicar en TestFlight/App Store desde CI | Xcode Cloud | `Kayuco · App Store Connect – API key` | rol App Manager, solo esta app | pendiente | 1 año (recordatorio en Todoist) | Crear llave nueva en App Store Connect → Usuarios y acceso → Integraciones; cargar en Xcode Cloud; borrar la anterior |
| `NOTARIZATION_PROFILE` | Notarizar el host de Mac | Xcode Cloud / Keychain de la Mac de build | `Kayuco · Apple – notarización` | mínimos | pendiente | 1 año | `xcrun notarytool store-credentials` con llave nueva |
| `HOMEBREW_TAP_TOKEN` | Publicar la fórmula del host en el tap | GitHub Secrets (`kayuco`) | `Kayuco · GitHub – tap token` | solo repo del tap, contenido | pendiente | 1 año | Token fino nuevo en GitHub; actualizar el secreto |

## 5. Usuarios de prueba
| Entorno | Usuario | Contraseña | Para qué |
|---|---|---|---|
| dev | Apple ID de prueba (sandbox) | entrada del gestor `Kayuco · Apple – sandbox tester` | Probar compras de StoreKit (pendiente) |

Nunca datos reales de personas ni contraseñas de producción.

## 6. Reconstruir desde cero
1. Clonar `kayuco` y `kayuco-apps`, correr `sh scripts/activar-candado.sh` y `bash scripts/check.sh`.
2. En developer.apple.com: crear los bundle IDs y el contenedor CloudKit de la sección 3; activar Xcode Cloud en los dos proyectos.
3. Cargar en Xcode Cloud los secretos de la sección 4 desde el gestor; en GitHub Secrets el del tap.
4. Compilar, notarizar, publicar el release del host; subir las apps a TestFlight interno; agregar al monitor de disponibilidad el sitio cuando exista (regla 29).

## 7. Vencimientos y revisión
- Recordatorio de cada vencimiento en Todoist (etiqueta `recordatorio`), dos semanas antes.
- Revisión de esta tabla cada seis meses junto con la prueba de recuperación (regla 30).
