# Manejo de Contexto — Guía de Presupuesto

## Presupuesto por sesión (aproximado)

| Elemento | Tokens | Cuándo se carga |
|----------|--------|-----------------|
| AGENTS.md | ~100 | Siempre |
| Rules (path-scoped) | ~200 | Solo si el path hace match |
| Skill activa | ~50-150 c/u | Bajo demanda |
| Definición de MCP | ~500+ | Al conectar un MCP |
| System prompt de Claude | ~2000 | Siempre |
| **Presupuesto útil restante** | **~1.5-2k** | Para trabajo real |

## Prácticas

### Una tarea por conversación
- `/clear` entre tareas no relacionadas
- No encadenar "ahora haz X, luego Y, luego Z" si son features distintas

### Investigaciones grandes → subagente
- Explorar >30 archivos → spawn de subagente (`Explore` o fork)
- El contexto principal queda limpio para el trabajo real

### Cuando el modelo se equivoca dos veces seguidas
- `/clear` y reiniciar con un prompt más específico
- No gastar contexto intentando "corregir" al modelo en el mismo hilo

### Nunca volcar el repo entero al contexto
- Usar `Glob` y `Grep` para búsquedas específicas
- Subagente de investigación para análisis de código amplio

## Anti-patrones de contexto

| Anti-patrón | Impacto | Alternativa |
|-------------|---------|-------------|
| "Lee todo el src/" | Agota contexto antes de empezar | Pedir al agente que explore solo lo que necesita |
| Misma sesión para 3 features | Contexto cruzado → errores | `/clear` entre features |
| AGENTS.md de 500 líneas | Ocupa todo el presupuesto | Mantener bajo ~150 líneas, apuntar a archivos |
| Skills redundantes cargadas siempre | +50-150 tokens por skill innecesaria | Solo cargar la skill cuando aplica |

## Rules de path scoping: por qué importan

Las rules se cargan SOLO cuando el archivo en edición hace match con el `path` del frontmatter. Esto significa:
- Editar `src/api/routes.ts` → carga `backend.md`, NO `frontend.md`
- Editar `src/components/Button.tsx` → carga `frontend.md` y `design.md`, NO `backend.md`

Resultado: ~200 tokens de rules, no 1000 tokens de todas las rules concatenadas.
