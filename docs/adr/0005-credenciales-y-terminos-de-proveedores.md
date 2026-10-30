# ADR 0005 — Kayuco nunca toca credenciales y respeta los términos de cada proveedor

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
En febrero de 2026 Anthropic aclaró que los tokens OAuth de suscripciones Claude Free/Pro/Max no pueden usarse en productos de terceros (incluido el Agent SDK); solo Claude Code y Claude.ai, y el acceso por API key sí está permitido. OpenCode retiró el soporte a cuentas Pro/Max. Otros proveedores tienen términos propios. Usar la marca de un proveedor en nombre, ícono o dominio también está fuera.

## Decisión
- Kayuco **no guarda, reenvía ni «presta» credenciales** de ningún proveedor. Cada agente lo instala y autentica el usuario.
- Para cada proveedor se usa solo el canal que sus términos permiten. Para Claude hoy: **API key** para dirigir; **observación** de Claude Code mediante sus puntos de extensión oficiales (hooks de notificación, permisos y fin de turno) para notificar y aprobar, sin conducirlo con credenciales de suscripción. Lanzar la CLI como subproceso no se asume permitido hasta verificarlo con la página de cumplimiento de Anthropic; en duda, se pregunta a su equipo.
- Antes del primer adaptador de cada proveedor se revisa y documenta su término aplicable en `docs/proveedores.md`.
- Nombre, ícono y dominio sin marcas de terceros; se dice «funciona con».

## Consecuencias
- El producto funciona completo con OpenCode, Codex y Gemini por sus canales permitidos, y con Claude por API key; la ruta por suscripción de Claude queda limitada a lo que Anthropic permita.
- Con API key, cada token preprocesado en local es dinero medible: refuerza la propuesta de valor.
- Decisión legal: la revisa y aprueba Eduardo, no un agente.
