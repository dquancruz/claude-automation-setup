---
name: threat-modeling
description: Modelado de amenazas con STRIDE, límites de confianza y análisis de superficie de ataque. Correr en fase de DISEÑO junto a solutions-expert, antes de implementar. Produce un modelo de amenazas con riesgos rankeados y mitigaciones concretas.
argument-hint: --component auth|api|infra|iot
tools: [Read, Write]
---

# Threat Modeling — STRIDE

## Cuándo ejecutar
En diseño (con solutions-expert), no durante implementación. Si el cambio toca auth, datos sensibles, red pública o IaC, ejecutar este análisis primero.

## STRIDE
| Amenaza | Descripción | Ejemplo |
|---------|-------------|---------|
| **S**poofing | Suplantar identidad | JWT falso, session hijacking |
| **T**ampering | Modificar datos | Parámetro IDOR, body injection |
| **R**epudiation | Negar acciones | Sin logs de audit |
| **I**nformation Disclosure | Exponer datos | Stack trace al cliente, S3 público |
| **D**enial of Service | Interrumpir servicio | Sin rate limit, memory leak |
| **E**levation of Privilege | Escalar permisos | RBAC mal implementado |

## Proceso (4 pasos)

### 1. Mapear el sistema
- Diagramar flujo de datos (DFD simple): actores → componentes → datos
- Identificar límites de confianza (internet ↔ API, API ↔ DB, user ↔ admin)
- Listar datos sensibles (PII, tokens, credenciales, datos de negocio)

### 2. Identificar amenazas
Por cada componente, aplicar STRIDE sistemáticamente.

### 3. Rankear por riesgo
```
Riesgo = Impacto × Probabilidad
- CRÍTICO: Impacto alto + Probabilidad alta → mitigar antes de launch
- ALTO: Impacto alto + Probabilidad media → mitigar en sprint actual
- MEDIO: mitigar en backlog prioritario
- BAJO: aceptar o monitorear
```

### 4. Definir mitigaciones
Para cada amenaza CRÍTICA/ALTA: qué control técnico la mitiga y quién la implementa.

## Notas por dominio

**API REST/GraphQL:** IDOR en parámetros, injection en filtros, rate limiting, CORS
**Frontend:** XSS (CSP estricto), CSRF (SameSite + token), exposición de env vars
**IoT/Edge:** Firmware sin firma, tráfico sin TLS, credenciales hardcodeadas en device
**Cloud (AWS):** Wildcards en IAM, S3 público, secretos en env del Lambda

## Output esperado
```markdown
## Modelo de amenazas — [Componente]
### Superficie de ataque
- [lista de entradas/salidas]
### Amenazas identificadas
| ID | Categoría | Descripción | Riesgo | Mitigación |
|----|-----------|-------------|--------|------------|
| T1 | Spoofing  | ...         | ALTO   | ...        |
### Próximos pasos
- [ ] Implementar [control X] — responsable: backend-expert
```
