# ADR 0006 — Dos repositorios: `kayuco` (público) y `kayuco-apps` (privado)

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
Open core (ADR 0003) exige separar lo que se abre de lo que se vende. Los secretos de firma y App Store Connect no pueden vivir en ningún repo.

## Decisión
- **`eduardothomas/kayuco` (público, Apache-2.0):** monorepo Swift con paquetes `KayucoCore` (protocolo host↔clientes, política de ruteo, cliente ACP, modelos de datos), `KayucoHost` (daemon y menu bar de Mac), `KayucoRunners` (simulador iOS, emulador Android, navegador), `docs/`, sitio y ADRs. Rama base `main`; `feature/*`, `fix/*`, `docs/*`; squash merge; releases por tags semver; CI Linux para `KayucoCore`; lo que requiera macOS se compila en Xcode Cloud.
- **`eduardothomas/kayuco-apps` (privado):** apps de iPhone, iPad y Watch, sync CloudKit, StoreKit, Live Activities, Siri. Depende de `KayucoCore` como paquete SPM por URL pública. Ramas `develop` (TestFlight) y `main` (App Store); `develop` → `main` con merge commit (regla 10 del estándar).
- **Secretos (regla 30 del estándar):** copia maestra en el gestor de contraseñas de Eduardo; copia de ejecución en Xcode Cloud (firma, perfiles, API de App Store Connect) o GitHub Secrets; inventario sin valores en `docs/infraestructura.md` de cada repo.

## Consecuencias
- Cambios al protocolo o a la política se hacen en `kayuco` y las apps los consumen por versión del paquete (ver ADR 0007).
- Abrir las apps después sería mover archivos; cerrar algo ya abierto no se puede.
