# Política de ruteo y delegación de modelos

**Fuente única** de la regla 27 del estándar. La leen Claude (chat y Claude Code), Codex, OpenCode, Gemini y cualquier otro agente, y más adelante la app Kayuco. Si cambia aquí, cambia en todos lados; no se copia a otros archivos, se enlaza.

## 1. Principio
El límite de uso de cada suscripción es el recurso escaso. Cada trabajo se hace con el modelo y el esfuerzo más bajos que den un resultado confiable; lo caro se reserva para donde un error cuesta caro. Barato y malo es peor que caro y bueno: un ruteo equivocado se paga dos veces.

## 2. Sesión principal (la conversación con Eduardo)
El modelo de la conversación lo elige Eduardo según el tipo de sesión; la tabla de la regla 27 (`STANDARD.md`) dice cuál conviene. Al iniciar, el agente dice en una línea si el modelo y el esfuerzo de la sesión son los adecuados para la tarea y, si no, cuál conviene. Eduardo decide si cambia.

## 3. Delegación (lo que el agente manda a subagentes o tareas programadas)
Cuatro roles fijos. El agente elige entre roles; no inventa configuraciones.

| Rol | Cuándo | Claude | Equivalente en otros agentes |
|---|---|---|---|
| **Explore** | Leer, buscar, resumir, inventariar archivos o logs; solo lectura | Haiku · low | el modelo más barato del proveedor, sin escritura |
| **implementador** | Implementar con spec clara y pruebas que lo verifiquen; cambios mecánicos; mover o copiar repos; documentación; correos; planes diarios | Sonnet · medium | modelo medio (GPT mini / Gemini Flash / equivalente) |
| **implementador-critico** | Dinero o cálculos legales (planilla, prestaciones, calculadoras), seguridad, auth o datos de usuarios, bugs difíciles, cambios que cruzan muchos módulos, código sin pruebas, rendimiento o concurrencia | Opus · high | modelo fuerte del proveedor (GPT alto / Gemini Pro / equivalente) |
| **revisor** | Revisar un diff contra la spec en contexto limpio (no vio el trabajo); solo reporta brechas de corrección | Opus · high | modelo fuerte, solo lectura |

**Qué no se delega:** cambios que caben en una frase, lo que depende de la conversación en curso, decisiones, arquitectura, diseño y la redacción de la spec. Eso se queda en la sesión principal.

**Cuándo sí se delega:** el trabajo ensucia el contexto (muchos archivos o logs), es paralelizable e independiente, o es verificable sin Eduardo (pruebas, CI).

**Escalar en vez de adivinar:** si el implementador falla las pruebas dos veces o descubre que la spec es ambigua, para y sube a implementador-critico o pregunta; no insiste con lo mismo. Todo lo que hizo un modelo barato pasa por pruebas/CI o por el revisor.

**Máximo dos trabajos pesados en paralelo** (Opus high o Fable).

**Revisor en Fable, solo si está disponible:** cuando el diff toca dinero, cálculos legales, seguridad o datos de usuarios y va a producción, el revisor corre en Fable · high si ese modelo está disponible y con cuota en ese momento; si no, se queda en Opus · high y el PR lo dice en una línea. Nunca se espera ni se bloquea una revisión por falta de Fable.

**Plantilla del prompt de delegación** (obligatoria): objetivo en una frase · archivos o rutas exactas · criterio de terminado (qué prueba debe pasar) · qué NO tocar · formato del reporte (3 líneas: qué hizo, qué probó, qué quedó).

## 4. Tareas programadas y recordatorios
- Recordatorio simple → Todoist con etiqueta `recordatorio` (cero tokens).
- Revisión que compara datos contra una meta → Sonnet · medium.
- Análisis con decisión o criterio (planes, cierres, estrategia) → Opus · high; Fable solo si Eduardo lo pide.
- Cada tarea programada declara su modelo al crearse; si la herramienta no lo permite al crear, se ajusta justo después.

## 5. Presupuesto y cascada
Cuando una suscripción se acerca a su límite (ventana de 5 horas o cuota semanal), el agente lo dice en una línea y propone delegar lo cerrado (spec + pruebas) a otro proveedor (Codex, Gemini u otro) en el mismo rol. No es regla pesada: una línea y Eduardo decide. Una vez al mes, revisar si el flujo con otros agentes sigue valiendo la pena.

## 6. Medición
Para poder afinar esta política con datos, cada delegación queda anotada donde ya se escribe el trabajo: en el **Traspaso** del PR (o en `estado-del-proyecto.md` si no hay PR) con una línea `Delegado a: <rol> (<modelo·esfuerzo>) → <resultado: ok / escalado / rehecho>`. Kayuco leerá esta política y registrará las mismas decisiones automáticamente.

## 7. Instalación por herramienta
- **Claude Code (Mac personal):** el bloque «Delegar modelos» de `agents/CLAUDE.md` ya importa este archivo; los cuatro roles están en `agents/claude-agents/` y se copian a `~/.claude/agents/`.
- **Claude en claude.ai:** skill `delegar-modelos` (`agents/skill-delegar-modelos/SKILL.md`), solo para sesiones grandes; el criterio base vive en la memoria de Claude.
- **Codex / OpenCode / Gemini:** `agents/AGENTS.md` enlaza este archivo; la columna «Equivalente en otros agentes» es la que aplican.
- **Claude del trabajo (Enterprise):** solo la versión genérica de la sección 3 (roles, cuándo delegar, escalar); sin menciones a proyectos, cuentas ni repos personales de Eduardo. No se versiona en repos del empleador (regla 28): va en `~/.claude/CLAUDE.md` de esa máquina o como skill personal de esa cuenta.
