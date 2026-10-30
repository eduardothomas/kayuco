# ADR 0003 — Open core: núcleo abierto con Apache-2.0, apps de pago

**Fecha:** 2026-10-30 · **Estado:** aceptada

## Contexto
Objetivos del proyecto: aprender Swift, construir en público, ganar audiencia (GitHub, X, YouTube) y generar ingresos. Todo abierto da fama sin ingresos; todo cerrado da ingresos sin difusión. GPL impide publicar en App Store sin fricción.

## Decisión
- **Abierto (este repo, Apache-2.0):** host de Mac, cliente ACP, política de ruteo, runners, protocolo host↔clientes, documentación. Contribuciones con DCO (sin CLA).
- **De pago (`kayuco-apps`, privado, App Store con compra universal):** apps de iPhone, iPad y Watch, sync CloudKit, Live Activities, Siri, StoreKit. Gratis con límites; Pro por suscripción; opción vitalicia limitada al lanzamiento. Más adelante, tier Team.
- Marca «Kayuco» registrada (DIGERPI primero); la licencia cubre código, no nombre.
- Atribuciones de terceros en `THIRD_PARTY_NOTICES.md`; nada con copyleft enlazado en el binario (si se usa, como proceso aparte).

## Consecuencias
- Dos repos y disciplina sobre qué va en cada uno.
- Soporte con canal único (Discussions) y SLA explícito de «mejor esfuerzo».
- Si algún día se abren las apps, es un movimiento de archivos; al revés sería casi imposible.
