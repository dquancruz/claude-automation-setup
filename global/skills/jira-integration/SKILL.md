---
name: jira-integration
description: Patrones para integración con Jira: crear épicas/historias/tareas, transicionar estados, linkear commits y cerrar tickets automáticamente al mergear. Usar cuando ticket-orchestrator genere jerarquía o cuando auto-jira.js deba interactuar con Jira.
argument-hint: --epic "Nombre del épico" --project PROJ
tools: [Bash, Read]
---

# Jira Integration Patterns

## Jerarquía de tickets
```
Epic (PROJ-120)
├─ Story (PROJ-121): API Endpoint
│  ├─ Task (PROJ-121a): Definir contrato
│  ├─ Task (PROJ-121b): Implementar
│  └─ Task (PROJ-121c): Tests + docs
└─ Story (PROJ-122): UI Component
   ├─ Task (PROJ-122a): Wireframe aprobado
   ├─ Task (PROJ-122b): Implementar componente
   └─ Task (PROJ-122c): Tests de accesibilidad
```

## Crear via MCP (Claude Code)
```
Usar el MCP de Jira para:
- Crear Epic con título, descripción y sprint
- Crear Stories bajo el Epic con acceptance criteria
- Crear Tasks bajo cada Story con estimaciones
```

## Transiciones de estado
- `To Do` → `In Progress` (al iniciar trabajo)
- `In Progress` → `In Review` (al abrir PR)
- `In Review` → `Done` (al mergear PR)

## Linkear commits a Jira
Incluir el ticket en el commit message:
```
feat(api): add date filter [PROJ-123]
```
El hook `prepare-commit-msg` extrae automáticamente el número del branch name.

## Cierre automático al mergear
El workflow `on-merge.yml` transiciona el ticket a Done al detectar `[PROJ-XXX]` en el título del PR.

## Reglas
- Un Story = una unidad de valor entregable
- Una Task = max 2-4 horas de trabajo
- Epic = no más de 2 semanas de trabajo
