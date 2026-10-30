# Kayuco — visión

**Fecha:** 30 de octubre de 2026 · **Dueño:** Eduardo Thomas · **Estado:** visión inicial, se afina con el dogfood

## Qué es
Kayuco es la cabina nativa Apple para trabajar con agentes de código. No es un agente ni un motor: es la capa que vive **fuera** del editor y **en el bolsillo**, desde la que ves, diriges, apruebas y mides lo que hacen OpenCode, Claude Code, Codex, Gemini CLI o cualquier agente que hable Agent Client Protocol (ACP), en cualquier proyecto (iOS, Android, web, backend), sin cambiar de herramienta.

Un cayuco es la canoa ligera con la que se cruza el Canal de Panamá en la carrera Ocean to Ocean: pequeño, rápido, hecho para ir de un lado a otro. Eso quiere ser la app.

## Por qué existe
1. Los agentes ya resuelven el trabajo; lo que falta es **dónde viven, cómo interrumpen y cuánto cuestan**. Hoy eso está en terminales abiertas en una Mac y en la cabeza del usuario.
2. Apple construyó la plomería (Foundation Models, Dynamic Profiles, ACP en Xcode 27) **dentro de Xcode y para el ecosistema Apple**. Kayuco ofrece el tablero **entre** herramientas, para cualquier stack, desde iPhone, iPad y Mac.
3. El límite de uso de cada suscripción es el recurso escaso. Preprocesar en local (clasificar, titular, resumir, extraer) y rutear cada tarea al modelo justo ahorra tokens de verdad, y con API key ahorra dinero medible.

## Para quién
Primero para Eduardo (dogfood real, todos los días). Después, developers que usan dos o más agentes, trabajan en Apple y quieren controlar costo y aprobaciones desde el celular. Más adelante, equipos pequeños con varias Macs host.

## Qué hace (producto completo)
- **Ver y dirigir** sesiones de cualquier agente ACP desde Mac, iPhone y iPad; mandar prompts; aprobar o rechazar herramientas desde una notificación, la pantalla bloqueada o el Watch.
- **Rutear**: política configurable que decide agente, modelo y esfuerzo por tarea; el orquestador es elegible (on-device, Private Cloud Compute, Claude, GPT, Gemini, local) y solo se adopta si mide igual o mejor que la alternativa de pago.
- **Preprocesar en local**: Foundation Models, Vision y Speech en la Mac (y en los dispositivos que lo soporten) antes de gastar tokens en la nube.
- **Correr sin cambiar de herramienta**: runners por tipo de proyecto (simulador iOS, emulador Android, navegador integrado o externo) con captura o video al celular.
- **Medir**: tokens y costo por proveedor, ventanas de uso, aciertos del ruteo, con Swift Charts.
- **Vivir en el sistema**: Live Activities, App Intents y Siri, Shortcuts, widgets, Spotlight, Share extension, Focus filters, menu bar, Servicios de Mac, Stage Manager y Pencil en iPad, Handoff y CloudKit entre dispositivos.

## Qué NO es
- No es un motor de agentes ni reemplaza a OpenCode/Claude Code/Codex.
- No ejecuta código en iPhone ni iPad (no hay shell); esos dispositivos dirigen al host de la Mac.
- No guarda, reenvía ni «presta» credenciales de ningún proveedor; cada agente lo instala y autentica el usuario y Kayuco usa solo los canales que ese proveedor permite (ver ADR 0005).
- No distribuye inferencia de modelos entre dispositivos (hoy no da calidad); rutea tareas por capacidad del dispositivo. Se revisa cada mes.

## Arquitectura en una línea
Agentes externos (ACP) → **Host** en la Mac (daemon Swift: sesiones, ruteo, runners, API local, relay de notificaciones) → **Clientes** nativos (menu bar, iPhone, iPad, Watch) → **Política** de ruteo y presupuestos (archivo versionable, sincronizada por CloudKit, con overrides por dispositivo).

## Modelo de negocio
Open core (ADR 0003): núcleo abierto con Apache-2.0 en este repo; apps de iPhone, iPad y Watch, sync y funciones de conveniencia de pago en App Store (`kayuco-apps`, privado). Gratis con límites; Pro por suscripción; opción vitalicia.

## Cómo se construye
Rápido y en público. Esqueleto completo primero, dogfood diario, una historia publicada a la vez (hilo de X, short, post largo cada dos semanas). Cada fase deja un video posible. Reglas del Estándar de Desarrollo de Software de Eduardo; este repo sí puede mostrar que se construyó con agentes.

## Fases (resumen)
0. Esqueleto: host + ACP con OpenCode, menu bar, app iPhone/iPad mínima, aprobaciones por notificación, Keychain, Bonjour.
1. Dogfood: runners, Live Activities, ruteo configurable con registro, presupuestos y cascada, Spotlight, Share, Stage Manager.
2. TestFlight público: CloudKit, Handoff, Siri/App Intents, Shortcuts, widgets, Charts, TipKit, Watch (simulador).
3. App Store: StoreKit, Focus filters, Servicios de Mac, atajos globales, Pencil, Continuity Camera, Vision, Speech.
4. Lo que Apple vaya soltando: Dynamic Profiles, adaptador entrenado de Foundation Models, Core AI, contexto personal de Siri, visionOS, CarPlay, plugin exo.

## Decisiones registradas
Ver `docs/adr/`. Toda decisión que cambie esta visión se registra como ADR nuevo, no se edita el anterior.
