# ADR 0007 — Entornos dev/prod conviviendo y compatibilidad entre versiones

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
Eduardo necesita usar la versión de desarrollo y la de producción en los mismos dispositivos (Mac, iPhone, iPad), y que una versión nueva del host no rompa a clientes viejos; si hay que romper, forzar actualización.

## Decisión
- **Dos bundle IDs por app** (`com.kayuco.app` y `com.kayuco.app.dev`) mediante build configurations; se instalan lado a lado, con ícono distinto (banda «DEV»). El host dev usa puerto y nombre Bonjour distintos; los clientes dev solo ven hosts dev.
- **CloudKit** usa sus ambientes Development y Production por build; el esquema se promueve a mano y solo con cambios aditivos (nunca renombrar ni borrar campos).
- **Protocolo host↔clientes versionado** en el handshake (`protocol`, `minClient`). Cambios aditivos por defecto. Si el host exige una versión mayor, el cliente muestra una pantalla bloqueante de «actualiza» con enlace al App Store.
- **Remote config** mínimo (JSON en el sitio o base pública de CloudKit) para versión mínima y kill switches sin esperar revisión de Apple.
- Flujo: `develop` → TestFlight interno → TestFlight externo → `main` → App Store con lanzamiento por fases. `develop` → `main` lo aprueba Eduardo.

## Consecuencias
- Dogfood real de lo nuevo sin perder la versión estable.
- Una regla de compatibilidad explícita para cada PR que toque el protocolo o el esquema.
