# ADR 0004 — Política de ruteo configurable, medida y con orquestador elegible

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
La regla de qué modelo y esfuerzo usar vive hoy en `agents/routing.md` del estándar de Eduardo y en su memoria con Claude. Un ruteo barato que acierte poco se paga dos veces. Los dispositivos no son iguales: un iPhone sin Apple Intelligence no tiene modelo on-device; una Mac sí.

## Decisión
- La política es un archivo versionable (misma forma que `routing.md` del estándar), **fuente de verdad en el host de la Mac**, sincronizada por CloudKit a la cuenta del usuario, con **overrides opcionales por dispositivo**.
- El **orquestador** (quien clasifica y delega) es elegible: Foundation Models on-device, Private Cloud Compute, Claude (Haiku/Sonnet/Opus), GPT, Gemini o un modelo local vía MLX/Ollama.
- **Nunca se adopta un orquestador sin medirlo:** Kayuco registra cada decisión (rol, modelo, esfuerzo, resultado: ok/escalado/rehecho, costo) y muestra el acierto de cada orquestador sobre las tareas del propio usuario. Un orquestador barato solo se usa si mide igual o mejor; el usuario fija el umbral.
- **Dos niveles:** el orquestador barato decide lo de bajo riesgo; si duda o la tarea toca producción, dinero, seguridad o datos, escala la decisión al orquestador fuerte.
- Dispositivos sin modelo on-device envían la clasificación al host o a PCC.

## Consecuencias
- La regla actual de Eduardo no cambia; cambia dónde se ejecuta y que se mide.
- Con suficientes decisiones registradas se puede entrenar un adaptador de Foundation Models (fase 4).
