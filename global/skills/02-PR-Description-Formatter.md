# 📝 SKILL: PR Description Formatter

**Para:** `~/.claude/skills/PR-Description-Formatter.md`

---

## 📋 CUÁNDO USAR ESTA SKILL

✅ Escribiendo descripción de pull request
✅ Auto-generación de PR description
✅ Estandarizando PRs en el equipo
✅ Validación de PR format antes de merge
✅ Documentación de cambios

---

## 🎯 FORMATO ESTÁNDAR

### Estructura General

```
[EMOJI] [TYPE] | [DESCRIPCIÓN] [TICKET]

## What
- Cambio 1
- Cambio 2
- Cambio 3

## Why
Razón del cambio, problema resuelto, beneficio.

## Testing
- Test 1: ✅ 
- Test 2: ✅ 
- Coverage: X%

## Related
- Jira: [LINK]
- Design: [LINK]
- Docs: [LINK]
```

---

## 🎨 EMOJIS Y TIPOS

### Feature (✨ Feature)
```
✨ Feature | Add date filter to reports [PROJ-123]

Usado cuando:
- Nueva funcionalidad
- Nuevo endpoint
- Nuevo componente UI
- Nueva capacidad
```

### Bug Fix (🐛 Fix)
```
🐛 Fix | Handle null dates in API [PROJ-124]

Usado cuando:
- Arreglando bug
- Fixing issue reportado
- Edge case handling
- Error handling improvement
```

### Refactor (♻️ Refactor)
```
♻️ Refactor | Extract validation logic to utils [PROJ-125]

Usado cuando:
- Reorganización de código
- Mejora de structure
- Extracción de duplicación
- Sin cambio funcional
```

### Documentation (📚 Docs)
```
📚 Docs | Update API documentation [PROJ-126]

Usado cuando:
- Actualizar README
- Actualizar API docs
- Agregar comments
- Update wiki
```

### Performance (⚡ Perf)
```
⚡ Perf | Optimize MongoDB aggregation pipeline [PROJ-127]

Usado cuando:
- Query optimization
- Memory optimization
- Load time improvement
- Bundle size reduction
```

### Security (🔒 Security)
```
🔒 Security | Add input validation to API [PROJ-128]

Usado cuando:
- Security vulnerability fix
- Input validation
- Authentication improvement
- Authorization improvement
```

### Tests (✅ Tests)
```
✅ Tests | Add integration tests for date filter [PROJ-129]

Usado cuando:
- Aumentando test coverage
- Adding test suite
- Test utility improvements
```

### Chore (🔧 Chore)
```
🔧 Chore | Update dependencies [PROJ-130]

Usado cuando:
- Dependency updates
- Build config changes
- CI/CD improvements
- Tooling updates
```

### Breaking Change (💥 Breaking)
```
💥 Breaking | Remove legacy API endpoint v1 [PROJ-131]

Usado cuando:
- API breaking change
- Parameter removal
- Response format change
- Requires migration
```

---

## 📋 SECCIONES DETALLADAS

### 1. What (Qué cambió)

Descripción técnica de los cambios. Debe ser:
- **Específico:** mencionar archivos/funciones/endpoints concretos
- **Detallado:** entendible sin ver el código
- **Conciso:** máximo 10 bullets

**Ejemplo para Feature:**
```
## What
- Added `GET /api/v1/reports?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD` endpoint
- Accepts ISO 8601 date format (YYYY-MM-DD)
- Returns 400 if dates invalid or startDate > endDate
- Returns 200 with filtered game reports (200-1000 records)
- Supports pagination: `limit=100&offset=0`
- Added MongoDB aggregation pipeline for efficient filtering
- Added Jira integration (links PR to PROJ-123)
```

**Ejemplo para Fix:**
```
## What
- Fixed null pointer exception when date is null
- Added null check in DateValidator
- Added default date range (last 30 days) if not provided
- Fixed timezone handling in date comparison
- Added test case for null dates
```

**Ejemplo para Refactor:**
```
## What
- Extracted DateValidator from ReportsController
- Created `src/utils/validators/date-validator.ts`
- Created `src/utils/validators/__tests__/date-validator.test.ts`
- Updated imports in ReportsController
- All existing tests pass (no functional change)
```

### 2. Why (Por qué cambió)

Contexto de negocio / problema resuelto. Responde:
- ¿Qué problema soluciona?
- ¿Para quién?
- ¿Por qué ahora?

**Ejemplo:**
```
## Why
Compliance reporting requires filtering data by date range. 
Currently, users export all data and manually filter in Excel (error-prone, slow).
This feature enables filtering at API level, improving accuracy and performance.
Required by [JIRA-123 - Compliance Requirements].
Requested by: Finance team
Deadline: End of Q2
```

### 3. Testing

Describe **CÓMO** se validó. Debe incluir:
- Tests unitarios: count + status
- Tests de integración: count + status
- Coverage: porcentaje exacto
- Manual testing: qué se probó
- Edge cases: qué se validó

**Formato:**
```
## Testing

### Unit Tests
✅ DateValidator: 8 tests passing
- Valid dates (YYYY-MM-DD format)
- Invalid dates (wrong format)
- Null handling
- Edge cases (leap years, year boundaries)

### Integration Tests
✅ ReportsController: 5 tests passing
- GET /api/v1/reports with date filter
- 200 response with correct data
- 400 response with invalid dates
- Pagination with filtered data
- Performance test (< 200ms for 10k records)

### Coverage
```
File                 | % Stmts | % Branches | % Funcs | % Lines
DateValidator.ts     | 100     | 100        | 100     | 100
ReportsController.ts | 95      | 90         | 100     | 95
All files            | 97      | 92         | 98      | 97
```

### Manual Testing
✅ Tested in Postman:
- Valid dates: returns filtered results
- Invalid format: returns 400 error
- Null dates: returns 400 error
- Large date range (1 year): performance OK (<500ms)
- Pagination: correct offset/limit behavior

### Performance
- Query time: < 200ms (10k records)
- Memory: < 50MB (peak)
- No N+1 queries
- MongoDB index used ✅
```

### 4. Related

Links a documentación, issues, diseño, etc.

```
## Related

### Jira
- [PROJ-123](https://jira.company.com/browse/PROJ-123) - Feature request
- [PROJ-125](https://jira.company.com/browse/PROJ-125) - Design review

### Design / Mocks
- [Figma - Reports Filter](https://figma.com/...)
- [API Contract - Confluence](https://wiki.company.com/...)

### Documentation
- [API Docs - Reports Endpoint](https://api-docs.company.com/reports)
- [User Guide - Filtering](https://wiki.company.com/reports-guide)

### Related PRs
- Depends on: [#445](https://github.com/org/repo/pull/445) (merged)
- Blocking: [#450](https://github.com/org/repo/pull/450) (ready for merge)

### Related Issues
- Closes: [#500](https://github.com/org/repo/issues/500)
- Related to: [#501](https://github.com/org/repo/issues/501)
```

---

## ✅ CHECKLIST DE VALIDACIÓN

Before marking PR ready for review, verify:

```markdown
- [ ] Title: [EMOJI] [TYPE] | [DESCRIPCIÓN] [TICKET]
  Example: ✨ Feature | Add date filter [PROJ-123]

- [ ] What section: 
  - [ ] Specific (file paths, function names, endpoints)
  - [ ] Detailed (understable without reading code)
  - [ ] Concise (max 10 bullets)

- [ ] Why section:
  - [ ] Problem statement clear
  - [ ] Stakeholders identified
  - [ ] Business value explained
  - [ ] Jira ticket linked

- [ ] Testing section:
  - [ ] Unit tests: count + passing
  - [ ] Integration tests: count + passing
  - [ ] Coverage: % shown (target >= 80%)
  - [ ] Manual testing: what was tested
  - [ ] Edge cases: documented

- [ ] Related section:
  - [ ] Jira links: 1+ ticket
  - [ ] Design/docs: links if applicable
  - [ ] Other PRs: dependencies noted

- [ ] Code quality:
  - [ ] All tests passing (100%)
  - [ ] Code review passed
  - [ ] No hardcoded values
  - [ ] No console.log left
  - [ ] Proper error handling

- [ ] PR metadata:
  - [ ] Labels: added (feature, bug, etc.)
  - [ ] Assignee: set
  - [ ] Reviewers: assigned
  - [ ] Projects: linked (if using GitHub Projects)

- [ ] No breaking changes (or documented):
  - [ ] API backward compatible? YES / NO
  - [ ] Database migration needed? YES / NO
  - [ ] Config changes? YES / NO
  - [ ] If YES: document in Why section
```

---

## 💥 BREAKING CHANGES

Si la PR tiene breaking changes, debe incluir:

```markdown
## What
[... as normal ...]

## Breaking Changes ⚠️

**API Endpoint Removed:**
```
DELETE /api/v1/reports/:id  ← No longer exists
```

Migration path:
```
Use DELETE /api/v2/reports/:id instead (same behavior)
```

**Timeline:**
- v2.0.0 (now): v1 endpoint removed
- v1.9.0 (last release with v1): deprecation warning added

**Impact:**
- Clients using `/api/v1/reports/:id` will get 404
- Estimated impact: 2-3 clients (coordinated upgrade planned)
```

---

## 🎯 EJEMPLOS COMPLETOS

### Ejemplo 1: Feature (Bueno)

```
✨ Feature | Add date range filtering to reports API [PROJ-123]

## What
- Added `GET /api/v1/reports` query parameters:
  - `startDate` (YYYY-MM-DD format, required)
  - `endDate` (YYYY-MM-DD format, required)
  - `limit` (1-1000, default 100)
  - `offset` (pagination, default 0)
- Returns 400 if dates invalid or startDate > endDate
- Returns 200 with array of filtered game reports
- Added MongoDB aggregation pipeline for efficient filtering
- Optimized with index on `timestamp` field

## Why
Finance team needs to filter reports by date for compliance reporting.
Previously, users exported all data and filtered in Excel (error-prone).
This API-level filtering improves accuracy, performance, and UX.
Required by [PROJ-123 - Q2 Compliance Requirements]
Stakeholders: Finance, Product, Backend
Timeline: Critical path for Q2 release

## Testing

### Unit Tests ✅
- DateValidator: 8/8 passing
  - Valid YYYY-MM-DD format
  - Invalid formats (MM-DD-YYYY, timestamps)
  - Null/undefined handling
  - Edge cases (leap years, century boundaries)

- ReportsAPI: 6/6 passing
  - Successful filter (200)
  - Invalid dates (400)
  - Missing required params (400)
  - Pagination limits (1-1000)

### Integration Tests ✅
- ReportsController: 5/5 passing
  - Filter by single day
  - Filter by date range (30-day span)
  - Pagination (offset/limit)
  - Performance (< 200ms for 10k records)
  - Concurrent requests (100 parallel)

### Coverage
```
File                     | Stmts | Branches | Funcs | Lines
src/utils/dateValidator  | 100%  | 100%     | 100%  | 100%
src/api/reportsAPI.ts    | 96%   | 92%      | 100%  | 96%
src/db/queries.ts        | 94%   | 88%      | 95%   | 94%
───────────────────────────────────────────────────────────
All files                | 97%   | 91%      | 98%   | 97%
```

### Manual Testing ✅
- Postman collection: [link](...)
  - ✅ Valid date range: returns 100 records
  - ✅ Invalid format: returns 400
  - ✅ startDate > endDate: returns 400
  - ✅ Pagination: offset works correctly
  - ✅ Performance: 5k records in < 150ms

## Related
- **Jira:** [PROJ-123](https://jira.company.com/browse/PROJ-123)
- **Design:** [API Contract - Confluence](https://wiki.company.com/api/reports)
- **Docs:** [API Reference](https://api.company.com/docs#reports)
```

### Ejemplo 2: Bug Fix (Bueno)

```
🐛 Fix | Handle null dates in reports API [PROJ-124]

## What
- Added null check in DateValidator
- Changed error code from 500 to 400 (for null dates)
- Returns 400 with message: "startDate and endDate are required"
- Previously: threw 500 error (server error)
- Now: throws 400 error (client error - bad request)

## Why
Users were seeing 500 errors when omitting date parameters.
Should be 400 (bad request) because it's client error.
Improves API contract compliance and debugging.

## Testing

### Unit Tests ✅
- DateValidator: test for null dates - passing
- ReportsAPI: test null params - passing

### Manual Testing ✅
- Omit both dates: 400 + proper message ✅
- Omit startDate: 400 + proper message ✅
- Include dates: 200 ✅

## Related
- **Jira:** [PROJ-124](https://jira.company.com/browse/PROJ-124)
- **Related to:** [#445](https://github.com/.../pull/445)
```

---

## ⚠️ ANTI-PATTERNS

❌ **Título sin emoji/type:**
```
❌ Add date filter
✅ ✨ Feature | Add date filter [PROJ-123]
```

❌ **What section too vague:**
```
❌ Added new feature
✅ Added GET /api/v1/reports with startDate, endDate parameters
```

❌ **Missing test results:**
```
❌ Tests were added
✅ Unit tests: 8/8 passing, Coverage: 97%
```

❌ **No problem statement in Why:**
```
❌ Finance team requested this
✅ Finance team needs to filter reports by date for compliance. 
   Previously done manually in Excel (error-prone).
```

❌ **Vague related links:**
```
❌ See the ticket
✅ [PROJ-123 - Compliance Requirements](https://jira.company.com/...)
```

---

**Última actualización:** 2026-06-04
**Estándar:** TELUS Video Services PR Format
