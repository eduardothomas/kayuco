# AGENTS.md — Kayuco

Este proyecto aplica el Estándar de Desarrollo de Software de Eduardo **v1.10** (`eduardothomas/software-development-standard`). Plataforma: **GitHub**. Repo **público** con Apache-2.0: aquí la atribución de agentes es normal y bienvenida (no aplica la regla 28).

## Arquitectura
Lee `docs/vision.md` y `docs/adr/` antes de proponer nada. Resumen: agentes externos vía ACP → host en la Mac (daemon Swift: sesiones, ruteo, runners, API local, relay de notificaciones) → clientes nativos (menu bar aquí; iPhone, iPad y Watch en `kayuco-apps`) → política de ruteo versionable.
Estructura prevista: `Packages/KayucoCore`, `Packages/KayucoRunners`, `Host/`.

## Comandos
- Instalar: `sh scripts/activar-candado.sh`
- Pruebas y build: `bash scripts/check.sh` (= `swift build && swift test` cuando exista `Package.swift`). Lo usan el candado pre-push y el CI (regla 26).
- Lo que requiera macOS (host, menu bar) se compila en Xcode Cloud, no en GitHub Actions (regla 23).

## Reglas del producto (no negociables)
- Kayuco no ejecuta código en iOS/iPadOS; dirige al host.
- Nunca guardar, reenviar ni «prestar» credenciales de proveedores de IA; usar solo los canales que cada proveedor permite (ADR 0005). Antes del primer adaptador de un proveedor, documentar su término aplicable en `docs/proveedores.md`.
- Nada de marcas de terceros en nombre, ícono o dominio.
- Cambios al protocolo host↔clientes o al esquema de CloudKit: aditivos y versionados (ADR 0007); si rompen, el PR lo dice y sube `minClient`.

## Flujo de Git
- Rama base: `main`. Ramas `feature/*`, `fix/*`, `docs/*` en español.
- Todo cambio entra por PR con pruebas y build ejecutados de verdad; squash merge.
- Releases por tags semver con changelog; producción (tag/release) solo con autorización de Eduardo.

## Continuidad entre sesiones
- Al iniciar: leer `estado-del-proyecto.md`, revisar PR abiertos y, si se continúa una rama, el Traspaso de su PR.
- Durante: commit y push frecuentes; PR en borrador desde el primer push.
- Al cerrar, aunque quede a medias: actualizar `estado-del-proyecto.md` y el Traspaso del PR, y hacer push.

## Modelos y delegación
- Política única en `agents/routing.md` del estándar (regla 27). Diseño, protocolo y decisiones en la sesión principal; implementación con spec y pruebas → implementador; seguridad, Keychain, ruteo de dinero/tokens y concurrencia → implementador-critico; revisor en contexto limpio antes de fusionar lo que hizo un modelo barato. Anotar cada delegación en el Traspaso del PR.

## Cuentas y secretos
- Inventario sin valores en `docs/infraestructura.md` (regla 30). Copia maestra en el gestor de Eduardo; copia de ejecución en Xcode Cloud o GitHub Secrets. Nunca imprimir ni guardar secretos ni pedirlos por chat.

## Decisiones y particularidades
- Construir en público: cada PR significativo puede convertirse en contenido (hilo de X, short). Dejar en el Traspaso una línea «Contenido posible: …» cuando aplique.
- Dispositivos de prueba de Eduardo: Mac Apple Silicon, iPhone SE (sin Apple Intelligence: no hay modelo on-device; probar la ruta «clasificación en el host»), iPad; Watch solo en simulador por ahora.
