# Estado del proyecto

**Proyecto:** Kayuco  
**Repositorio:** https://github.com/eduardothomas/kayuco  
**Estándar adoptado:** software-development-standard v1.10  
**Plataforma:** GitHub  
**Última actualización:** 2026-10-31 por Claude

> Léelo al iniciar cualquier sesión y actualízalo al cerrarla (regla 25 del estándar). El trabajo que aún no se integra se describe en el Traspaso de su PR.

## Resumen
Cabina nativa Apple sobre agentes de código (ACP). Fase 0 en curso: `Packages/KayucoCore` tiene los modelos del protocolo host↔clientes y de la política de ruteo, con 55 pruebas. Falta el host mínimo con ACP. Repo hermano privado: `kayuco-apps`.

## Trabajo en curso
| Rama | PR | Quién | Estado | Siguiente paso |
|---|---|---|---|---|
| feature/kayuco-core | [#2](https://github.com/eduardothomas/kayuco/pull/2) | Claude | listo para revisión | Eduardo revisa y fusiona (squash) |

## Última sesión
- **Fecha y actor:** 2026-10-31 · Claude (Opus 5.5, high) en Claude Code, en la Mac personal.
- **Rama / PR:** feature/kayuco-core · #2.
- **Hecho:**
  - `Packages/KayucoCore` (tools 6.1, macOS/iOS 26).
  - Protocolo versionado (ADR 0007): handshake `protocol`/`minClient`/entorno, sesión, mensaje, aprobación de herramienta con opciones ACP, envoltorios `type`/`payload` y enums abiertos.
  - Política de ruteo (ADR 0004): 4 roles, orquestador de dos niveles, overrides por dispositivo, y un parser de Markdown con la forma de `agents/routing.md`.
  - `check.sh` recorre `Packages/*`; el CI corre en el contenedor `swift:6.1`.
- **Pruebas:**
  - `bash scripts/check.sh` → 55 pruebas en 8 suites pasan (macOS, Swift 6.4).
  - CI de Linux con Swift 6.1: verde en la corrida previa a los arreglos del revisor; el último commit todavía no tenía resultado al cerrar.
- **Quedó en:** PR completo; los 9 hallazgos del revisor que se corrigieron ya están en la rama.
- **Siguiente paso:** host mínimo (`Host/`) que hable ACP con OpenCode usando `KayucoCore`; antes, `docs/proveedores.md` con el término de OpenCode (ADR 0005).
- **Espera a Eduardo:** fusionar #2; dominio; términos de proveedores (ADR 0005).

## Funcionalidades terminadas
- [ ] (ninguna integrada todavía; KayucoCore en #2)

## Fuera del repositorio
- Repo `eduardothomas/kayuco-apps` (privado) creado el 2026-10-30.
- Dominio: pendiente de verificar y comprar.
- Xcode Cloud, App Store Connect, CloudKit: pendientes.

## Decisiones importantes
- 2026-10-30:
  - Capa sobre agentes, no motor (ADR 0001).
  - ACP como contrato (ADR 0002).
  - Open core Apache-2.0 + apps de pago (ADR 0003).
  - Ruteo configurable y medido (ADR 0004).
  - Sin credenciales de terceros y respeto a términos (ADR 0005).
  - Dos repos (ADR 0006).
  - Dev/prod conviviendo y compatibilidad (ADR 0007).
- 2026-10-31:
  - Los enums del cable son abiertos (`unknown(raw)`), y un `type` desconocido no es error: así un cliente viejo no se rompe con cambios aditivos.
  - Las fechas del cable van en ISO 8601 con milisegundos.
  - La política se escribe en el mismo Markdown que `routing.md`, con las secciones opcionales `## Orquestador` y `## Overrides por dispositivo`.

## Riesgos o bloqueos
- Términos de uso de suscripciones de proveedores (Anthropic restringe OAuth de suscripción en terceros): la ruta para Claude es API key u observación por hooks; revisar antes de cada adaptador (ADR 0005).
- Riesgo Apple: Xcode 27 orquesta agentes dentro de Xcode; defensa: agnóstico de IDE y stack, y presencia en iPhone/iPad/Watch.
- Alcance: muchas capacidades posibles; una historia publicada a la vez.
- El JSON de `RoutingPolicy` usa enums cerrados (`Role`, `Effort`, `Orchestrator`). Si se sincroniza por CloudKit como JSON y no como Markdown, hay que abrirlos antes.

## Pendientes
- [ ] Fase 0, lo que falta: host mínimo con ACP + OpenCode, menu bar, app iPhone/iPad mínima, aprobaciones por notificación, Keychain y Bonjour.
- [ ] `docs/proveedores.md` con el término aplicable de cada proveedor.
- [ ] Dominio y marca (DIGERPI).
- [ ] Lista de espera / TestFlight público cuando exista la app.

## Bitácora (últimas 5 sesiones)
- 2026-10-31 · Claude · feature/kayuco-core · KayucoCore: protocolo, política de ruteo, parser y pruebas.
- 2026-10-30 · Claude · docs/vision-y-arranque · Visión, ADRs y base del repo.
