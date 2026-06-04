# 📌 SKILL: Semantic Versioning Control

**Para:** `~/.claude/skills/Semantic-Versioning-Control.md`

---

## 📋 CUÁNDO USAR ESTA SKILL

✅ Auto-detectar MAJOR/MINOR/PATCH en commits
✅ Auto-actualizar versión en package.json
✅ Auto-finalizar CHANGELOG.md
✅ Auto-crear git tags
✅ Auto-crear GitHub releases

---

## 🎯 SEMANTIC VERSIONING (SemVer)

### Formato: MAJOR.MINOR.PATCH

**MAJOR (X.0.0):** Breaking changes
```
Ejemplos:
- API endpoint removed
- Parameter removed from endpoint
- Response schema changed
- Database migration required
- Configuration breaking change

Incrementa MAJOR cuando:
1. API no es backward compatible
2. Cambio requiere acción de clientes
3. Cambio requiere migration

Ejemplo: 1.5.3 → 2.0.0
```

**MINOR (0.X.0):** New features (backward compatible)
```
Ejemplos:
- New endpoint added
- New optional parameter
- New response field (optional)
- New config option
- Database migration optional (backward compatible)

Incrementa MINOR cuando:
1. Agregar funcionalidad nueva
2. Agregar pero sin romper compatibilidad
3. Extender sin quitar

Ejemplo: 1.5.3 → 1.6.0
```

**PATCH (0.0.X):** Bug fixes (no new features)
```
Ejemplos:
- Fix calculation bug
- Fix null pointer exception
- Fix performance issue
- Fix error message typo
- Fix memory leak

Incrementa PATCH cuando:
1. Arreglar bug
2. Mejorar performance
3. Sin agregar features nuevas

Ejemplo: 1.5.3 → 1.5.4
```

---

## 🔍 AUTO-DETECTION RULES

Analiza commits desde último tag y detecta automáticamente:

```
PASO 1: Scan commits desde último tag hasta HEAD
├─ git log --oneline <last-tag>..HEAD
└─ Busca en mensaje de commit

PASO 2: Buscar palabras clave
├─ "BREAKING CHANGE:" en body → MAJOR
├─ "feat(" en título → MINOR
├─ "fix(" en título → PATCH
├─ "refactor(" en título → PATCH
├─ "docs(" en título → NO CHANGE (0.0.0)
├─ "test(" en título → NO CHANGE (0.0.0)
└─ "chore(" en título → NO CHANGE (0.0.0)

PASO 3: Determinar versión final
├─ Si hay BREAKING: MAJOR (ignorar MINOR/PATCH)
├─ Si hay feat: MINOR (ignorar PATCH)
├─ Si hay fix: PATCH
└─ Si solo docs/test/chore: NO CHANGE
```

### Ejemplo:

```
Current version: 2.1.3

Commits since 2.1.3:
├─ feat(reports): add date filter → MINOR ↗
├─ fix(api): null date handling → PATCH
├─ docs(readme): update api section → IGNORE
└─ feat(ui): new component → MINOR ↗

Result: MINOR (múltiples feat)
Final version: 2.1.3 → 2.2.0
```

---

## 📝 CHANGELOG FORMAT (Keep a Changelog)

Ubicación: `CHANGELOG.md` en raíz del repo

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New features that are not yet released

### Changed
- Changes in existing functionality

### Deprecated
- Features that will be removed in future versions

### Removed
- Features that have been removed

### Fixed
- Bug fixes

### Security
- Vulnerabilities fixes

## [2.2.0] - 2026-06-04

### Added
- [PROJ-123] Date range filtering to reports API
- [PROJ-124] MongoDB aggregation pipeline optimization
- Date validator utility with comprehensive tests

### Fixed
- [PROJ-124] Handle null dates in reports endpoint (returns 400, not 500)

### Security
- [PROJ-126] Add input validation to all API endpoints

## [2.1.3] - 2026-05-28

### Fixed
- [PROJ-120] Memory leak in WebSocket manager
- [PROJ-121] CPU throttling on Raspberry Pi

## [2.1.0] - 2026-05-15

### Added
- [PROJ-110] WebSocket support for real-time scoring
- [PROJ-111] Offline message queue for clients

---

[Unreleased]: https://github.com/org/repo/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/org/repo/releases/tag/v2.2.0
[2.1.3]: https://github.com/org/repo/releases/tag/v2.1.3
[2.1.0]: https://github.com/org/repo/releases/tag/v2.1.0
```

---

## 🔧 AUTO-VERSIONING WORKFLOW

### Paso 1: Detectar cambios

```bash
# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0)
COMMITS=$(git log --oneline $LAST_TAG..HEAD)

# Analyze for MAJOR/MINOR/PATCH
# (como se describe arriba)
```

### Paso 2: Update package.json

```json
// Antes:
{
  "name": "boliche-api",
  "version": "2.1.3",
  "description": "..."
}

// Después (si MINOR):
{
  "name": "boliche-api",
  "version": "2.2.0",  ← UPDATED
  "description": "..."
}
```

### Paso 3: Finalizar CHANGELOG.md

```markdown
// Antes:
## [Unreleased]
### Added
- [PROJ-123] Date filtering
- [PROJ-124] Aggregation optimization

## [2.1.3] - 2026-05-28
...

// Después:
## [2.2.0] - 2026-06-04  ← NEW SECTION
### Added
- [PROJ-123] Date filtering
- [PROJ-124] Aggregation optimization

## [2.1.3] - 2026-05-28
...
```

### Paso 4: Create git tag

```bash
# Create annotated tag
git tag -a v2.2.0 -m "Release v2.2.0: Add date filtering"

# Push tag
git push origin v2.2.0
```

### Paso 5: Create GitHub release

```
Release v2.2.0

**Release Date:** 2026-06-04

## What's New

### Added
- [PROJ-123] Date range filtering to reports API
- MongoDB aggregation optimization
- Comprehensive date validator tests

### Fixed
- [PROJ-124] Handle null dates properly (400 error)

### Breaking Changes
None

## Migration Guide
No migration needed. New features are backward compatible.

## Downloads
- [Source code (zip)](...)
- [Source code (tar.gz)](...)
```

---

## 📋 VERSIONING CHECKLIST

Before tagging:

```markdown
- [ ] All commits analyzed and categorized
- [ ] MAJOR/MINOR/PATCH correctly detected
- [ ] package.json version updated
- [ ] CHANGELOG.md finalized with:
  - [ ] New [X.Y.Z] - DATE section
  - [ ] All commits categorized (Added/Fixed/Changed/etc)
  - [ ] Jira references included ([PROJ-XXX])
  - [ ] Migration guide (if MAJOR)
  - [ ] Breaking changes noted (if MAJOR)
- [ ] All tests passing
- [ ] Build successful
- [ ] git tag created (v X.Y.Z)
- [ ] GitHub release published with description
- [ ] Announcement posted (Slack, team, etc)
```

---

## 🎯 EXAMPLES

### Example 1: Feature Release (MINOR)

```
Current: 2.1.3
Commits:
├─ feat(reports): add date filter [PROJ-123]
├─ feat(ui): new dashboard [PROJ-125]
├─ fix(api): null handling
└─ docs(readme): update

Detection: MINOR (has feat)
Result: 2.1.3 → 2.2.0

CHANGELOG:
## [2.2.0] - 2026-06-04

### Added
- [PROJ-123] Date range filtering to reports API
- [PROJ-125] New dashboard UI component

### Fixed
- [PROJ-124] Handle null dates properly

---

Migration: No migration needed (backward compatible)
```

### Example 2: Breaking Release (MAJOR)

```
Current: 2.1.3
Commits:
├─ feat(api): refactor endpoints v1 → v2 [PROJ-130]
├─ BREAKING CHANGE: Remove /api/v1/reports endpoint
├─ feat(api): add /api/v2/reports (new schema)
└─ docs(migration): add v1→v2 guide [PROJ-131]

Detection: MAJOR (has BREAKING CHANGE)
Result: 2.1.3 → 3.0.0

CHANGELOG:
## [3.0.0] - 2026-06-04

### Added
- [PROJ-130] New /api/v2/reports endpoint (improved schema)

### Changed
- [PROJ-130] Refactored all endpoints for consistency

### Removed
- [PROJ-130] Removed legacy /api/v1/reports endpoint (use v2)

### Breaking Changes
**API v1 deprecated:** See migration guide below

### Migration Guide
```
Old: GET /api/v1/reports/:id
New: GET /api/v2/reports/:id
```

Response schema changed:
```
// Old
{ id, name, score, ... }

// New
{ id, name, total_score, frames: [...], ... }
```

Timeline: v1 removed in 3.0.0 (use v2 instead)
Clients affected: 2-3 (coordinate upgrade)

---

## Example 3: Patch Release (PATCH)

```
Current: 2.1.3
Commits:
├─ fix(api): fix null pointer in scoring
├─ fix(pi): handle memory pressure correctly
└─ perf(db): optimize index usage

Detection: PATCH (only fix/perf)
Result: 2.1.3 → 2.1.4

CHANGELOG:
## [2.1.4] - 2026-06-04

### Fixed
- Null pointer exception in scoring logic
- Memory pressure handling on Raspberry Pi
- Database index optimization
```

---

## ⚠️ EDGE CASES

### No changes (only docs/chore)
```
Current: 2.1.3
Commits:
├─ docs(readme): update
├─ chore(deps): update dependencies

Detection: NO CHANGE (ignore docs/chore)
Result: 2.1.3 (no bump)

Action: Don't create tag, don't update CHANGELOG
```

### Multiple breaking changes
```
Current: 2.1.3
Commits:
├─ feat(api): new endpoint
├─ BREAKING CHANGE: remove old endpoint
├─ BREAKING CHANGE: rename field in response

Detection: MAJOR (multiple breaking changes)
Result: 2.1.3 → 3.0.0
Note: Only increment MAJOR once (2.1.3 → 3.0.0, not 4.0.0)
```

### Pre-release version
```
Current: 2.2.0-beta.1 (pre-release)
Commits: [FINAL fixes]

Detection: PATCH to release
Result: 2.2.0-beta.1 → 2.2.0 (remove -beta)

CHANGELOG:
## [2.2.0] - 2026-06-04 (Released from 2.2.0-beta.1)
...
```

---

## 🤖 AUTOMATION SCRIPT PSEUDOCODE

```python
def auto_version():
    # Get last tag
    last_tag = get_last_git_tag()  # e.g., v2.1.3
    
    # Get commits since tag
    commits = git_log(f"{last_tag}..HEAD")
    
    # Detect change type
    has_breaking = any("BREAKING" in c for c in commits)
    has_feat = any("feat(" in c for c in commits)
    has_fix = any("fix(" in c for c in commits)
    
    # Determine next version
    if has_breaking:
        bump_type = "MAJOR"
    elif has_feat:
        bump_type = "MINOR"
    elif has_fix:
        bump_type = "PATCH"
    else:
        print("No version bump needed")
        return
    
    # Calculate new version
    current_version = parse_version(last_tag)  # e.g., (2, 1, 3)
    new_version = increment(current_version, bump_type)  # (2, 2, 0)
    
    # Update package.json
    update_package_json(new_version)
    
    # Update CHANGELOG.md
    update_changelog(new_version, commits)
    
    # Create git tag
    git_tag(f"v{new_version}")
    
    # Create GitHub release
    github_create_release(f"v{new_version}", changelog_entry)
    
    print(f"✅ Versioned {current_version} → {new_version}")

auto_version()
```

---

**Última actualización:** 2026-06-04
**Estándar:** Semantic Versioning 2.0.0 + Keep a Changelog
