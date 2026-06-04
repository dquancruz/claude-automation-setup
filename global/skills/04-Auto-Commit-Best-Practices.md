# 🔗 SKILL: Auto-Commit Best Practices

**Para:** `~/.claude/skills/Auto-Commit-Best-Practices.md`

---

## 📋 CUÁNDO USAR ESTA SKILL

✅ Backend-expert o frontend-expert completó código
✅ Todos los tests pasan
✅ Code review pasó
✅ Listo para fazer commit automático
✅ Script auto-commit.js va a usar esta skill

---

## 🎯 COMMIT MESSAGE FORMAT

### Conventional Commits (RFC)

```
<type>(<scope>): <subject> [<ticket>]

<body>

<footer>
```

### Types

```
feat:      A new feature
fix:       A bug fix
refactor:  Code change that neither fixes a bug nor adds feature
perf:      Code change that improves performance
test:      Adding or updating tests
docs:      Documentation only changes
style:     Formatting, semicolons, etc (no code logic change)
chore:     Dependency updates, build changes, etc
ci:        CI/CD pipeline changes
```

### Scope (Optional)

Qué parte del código cambió:

```
feat(reports): add date filter        ← reports module
fix(api): handle null dates           ← api layer
test(scoring): add edge cases         ← scoring module
docs(readme): update setup            ← documentation
```

### Subject (Mandatory)

- Imperative tone: "add" not "adds" or "added"
- Don't capitalize first letter
- No period (.) at end
- Max 50 characters
- Should complete: "If applied, this commit will <subject>"

```
✅ add date filter to reports API
❌ Added date filter to reports API
❌ adds date filter to reports API
❌ add date filter to reports API.
```

### Ticket Reference (Mandatory for features)

```
feat(reports): add date filter [PROJ-123]
^              ^                 ^
type           description       ticket
```

### Body (Optional for small commits, Mandatory for large)

More detailed explanation of the change. Include:

```
- What changed and why
- How it works
- Edge cases handled
- Performance implications

Example:
---
feat(reports): add date range filtering [PROJ-123]

Added query parameters to GET /api/v1/reports:
- startDate (YYYY-MM-DD): beginning of range
- endDate (YYYY-MM-DD): end of range
- limit (1-1000): pagination limit, default 100
- offset: pagination offset, default 0

MongoDB aggregation pipeline filters by $gte/$lte.
Index on timestamp field optimizes query performance.

Handles edge cases:
- startDate > endDate: returns 400
- Invalid date format: returns 400
- No parameters: uses default (last 30 days)
```

### Footer (Optional)

For breaking changes or related issues:

```
feat!: breaking API change

BREAKING CHANGE: /api/v1/reports removed, use /api/v2/reports

Closes #123
Relates to #124
```

---

## ✅ PRE-COMMIT VALIDATIONS

Before `git commit`, verify:

### 1. No Secrets in Code

```bash
# Check for common secrets
grep -r "GITHUB_TOKEN\|API_KEY\|password\|secret" src/
grep -r "mongodb://\|DATABASE_URL" src/

# All tests MUST pass
npm test

# All linting MUST pass
npm run lint

# TypeScript type checking MUST pass
npx tsc --noEmit
```

### 2. Code Quality

```
✅ No console.log() left
✅ No hardcoded values (use env vars)
✅ No .only() in tests (runs all tests)
✅ No .skip() in tests (skips unfinished)
✅ Proper error handling (no silent failures)
✅ Comments where needed (complex logic)
✅ No dead code (unused imports, variables)
```

### 3. Tests Passing

```
✅ Unit tests: 100% passing
✅ Integration tests: 100% passing
✅ Coverage: >= 80% (ideally >= 90%)
✅ No test warnings
✅ No timeout failures
```

### 4. Formatting

```
✅ Code formatted (prettier)
✅ Linted (eslint)
✅ Type-checked (typescript)
✅ No trailing whitespace
✅ Correct file endings
```

---

## 🔐 GPG SIGNING (Optional but Recommended)

Sign commits for security:

```bash
# Setup GPG key
gpg --gen-key

# Configure git
git config --global user.signingkey <key-id>
git config --global commit.gpgSign true

# Verify signature
git log --show-signature

# Add GPG public key to GitHub
# Settings → SSH and GPG keys → New GPG key
```

Commits signed con:
```
commit abc123def456
gpg: Signed by: John Doe <john@company.com>
gpg: Good signature from "John Doe"
```

---

## 🚀 AUTO-COMMIT WORKFLOW

### Step 1: Code is complete & tested

```
Backend-expert or Frontend-expert:
├─ Tests passing: 12/12 ✅
├─ Coverage: 97% ✅
├─ Code reviewed: approved ✅
├─ No secrets: verified ✅
└─ Ready for commit
```

### Step 2: Script validates

```bash
# scripts/auto-commit.js runs:
1. git status --porcelain
   (verify files to commit)

2. npm test
   (run full test suite)

3. npx tsc --noEmit
   (verify no type errors)

4. npm run lint
   (verify code quality)

# If any fails: abort, don't commit
# If all pass: continue to step 3
```

### Step 3: Script creates commit

```bash
# Stage files
git add <files>

# Create message
MESSAGE="feat(reports): add date filter [PROJ-123]

- Added MongoDB aggregation pipeline
- Added input validation
- Added comprehensive tests

Tests: 12/12 passing
Coverage: 100%"

# Sign and commit
git -c user.name="Auto Agent" \
    -c user.email="agent@company.com" \
    -S \
    commit -m "$MESSAGE"

# Get SHA
SHA=$(git rev-parse HEAD)
echo "✅ Committed: $SHA"
```

### Step 4: Script pushes (optional)

```bash
# Push to feature branch (NOT main)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin $BRANCH

# Verify push
git log -1 --oneline origin/$BRANCH
echo "✅ Pushed to origin/$BRANCH"
```

---

## 📋 COMMIT MESSAGE EXAMPLES

### Example 1: Simple Fix
```
fix(api): handle null date validation

Returns 400 instead of 500 when date is null
```

### Example 2: Feature with Details
```
feat(reports): add date range filtering [PROJ-123]

Added query parameters to GET /api/v1/reports:
- startDate (YYYY-MM-DD): beginning of range  
- endDate (YYYY-MM-DD): end of range
- limit (1-1000): pagination limit
- offset: pagination offset

MongoDB aggregation pipeline filters by timestamp.
Index on timestamp field ensures < 200ms query time.

Edge cases handled:
- startDate > endDate → 400 error
- Invalid date format → 400 error  
- Missing params → uses defaults

Tests: 12/12 passing, Coverage: 100%
```

### Example 3: Refactor
```
refactor(api): extract validation to utils

Moved DateValidator from ReportsController to utils/validators.
All existing tests pass (no functional change).
Improves code reusability and testability.
```

### Example 4: Breaking Change
```
feat!: remove legacy API v1 endpoints [PROJ-130]

BREAKING CHANGE: /api/v1/reports and /api/v1/games removed
Use /api/v2/reports and /api/v2/games instead

Migration guide: [PROJ-131 confluence link]
Clients affected: 2-3 (coordinate upgrade)
```

---

## ⚠️ ANTI-PATTERNS

❌ **Vague message:**
```
❌ git commit -m "fix stuff"
✅ git commit -m "fix(api): handle null dates in filter endpoint"
```

❌ **Too long subject:**
```
❌ fix(api): implement comprehensive null date handling with error messages
✅ fix(api): handle null dates properly
```

❌ **Without ticket:**
```
❌ feat(reports): add date filter
✅ feat(reports): add date filter [PROJ-123]
```

❌ **Capitalized subject:**
```
❌ feat(reports): Add date filter
✅ feat(reports): add date filter
```

❌ **Period at end:**
```
❌ feat(reports): add date filter.
✅ feat(reports): add date filter
```

❌ **Past tense:**
```
❌ feat(reports): added date filter
✅ feat(reports): add date filter
```

❌ **No type:**
```
❌ reports: add date filter
✅ feat(reports): add date filter
```

---

## 🤖 PSEUDO-CODE: auto-commit.js

```javascript
async function autoCommit(options) {
  const {
    message,      // Full commit message
    files,        // Files to stage
    branch,       // Feature branch name
    jira_ref,     // Optional: PROJ-123
    push = false  // Push after commit?
  } = options;

  // Step 1: Validate
  try {
    // Check tests
    execSync('npm test --bail');
    
    // Check types
    execSync('npx tsc --noEmit');
    
    // Check lint
    execSync('npm run lint');
  } catch (error) {
    console.error('❌ Validation failed:', error.message);
    return { success: false, error: error.message };
  }

  // Step 2: Stage files
  try {
    execSync(`git add ${files.join(' ')}`);
  } catch (error) {
    console.error('❌ Staging failed:', error.message);
    return { success: false, error: error.message };
  }

  // Step 3: Commit
  try {
    const fullMessage = jira_ref 
      ? `${message} [${jira_ref}]`
      : message;
    
    execSync(`git commit -S -m "${fullMessage}"`, {
      env: { ...process.env, GIT_AUTHOR_NAME: 'Auto Agent' }
    });
    
    const sha = execSync('git rev-parse HEAD').toString().trim().slice(0, 7);
    console.log(`✅ Committed: ${sha}`);
    
    // Step 4: Optional push
    if (push) {
      execSync(`git push origin ${branch}`);
      console.log(`✅ Pushed to origin/${branch}`);
    }
    
    return { success: true, sha, message: fullMessage };
  } catch (error) {
    console.error('❌ Commit failed:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { autoCommit };
```

---

**Última actualización:** 2026-06-04
**Estándar:** Conventional Commits (RFC)
