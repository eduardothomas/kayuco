# ADR 0002 — Agent Client Protocol (ACP) como contrato con los agentes

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
Hablar con cada agente por su API propia significa N integraciones frágiles. ACP es el protocolo abierto que Zed y Xcode 27 adoptaron para conectar agentes; Claude Code, Codex y Gemini CLI tienen adaptadores.

## Decisión
El host de Kayuco habla ACP con los agentes. Un agente que no lo hable entra con un adaptador fino que traduce a ACP, nunca con una integración especial dentro de Kayuco. El protocolo host↔clientes de Kayuco es propio, versionado y mínimo (ver ADR 0007).

## Consecuencias
- Cualquier agente ACP futuro entra sin cambiar Kayuco.
- Las capacidades que ACP no cubra (costos por proveedor, ventanas de uso) se obtienen por observación (hooks, logs) o por API key, nunca extrayendo credenciales del agente.
