# ADR 0001 — Kayuco es una capa sobre agentes existentes, no un motor propio

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
OpenCode, Claude Code, Codex y Gemini CLI ya resuelven el loop de herramientas, LSP, sandboxing, permisos y decenas de proveedores, y cambian su API cada mes. Reescribir eso es un año de trabajo que nadie nota; lo que sí se nota es dónde viven los agentes, cómo interrumpen y cuánto cuestan.

## Decisión
Kayuco no implementa un motor de agentes. Orquesta, observa y dirige agentes externos. La Mac es el host que ejecuta; iPhone, iPad y Watch son clientes que dirigen y aprueban; nada se ejecuta en iOS.

## Consecuencias
- Cero mantenimiento de integraciones con proveedores de modelos: eso lo hace cada agente.
- El valor diferencial se concentra en experiencia nativa, interrupciones inteligentes, ruteo, runners y medición.
- Dependencia de que los agentes expongan un canal de control (ver ADR 0002) y de los términos de cada proveedor (ver ADR 0005).
