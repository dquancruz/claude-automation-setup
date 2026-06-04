# 🔄 SKILL: Jira Integration Patterns

**Para:** `~/.claude/skills/Jira-Integration-Patterns.md`

---

## 📋 CUÁNDO USAR ESTA SKILL

✅ Feature description recibida
✅ Auto-crear Epic en Jira
✅ Auto-crear Stories bajo Epic
✅ Auto-crear Tasks bajo Stories
✅ Auto-transicionar estados
✅ Auto-linkear commits a Jira
✅ Auto-cerrar tickets cuando PR mergea

---

## 🎯 JIRA STRUCTURE FOR FEATURES

### Hierarchy

```
Epic (PROJ-120)
├─ Story (PROJ-121): API Endpoint
│  ├─ Task (PROJ-121a): Define contract
│  ├─ Task (PROJ-121b): Implement
│  └─ Task (PROJ-121c): Tests & docs
│
├─ Story (PROJ-122): UI Component
│  ├─ Task (PROJ-122a): Design
│  ├─ Task (PROJ-122b): Implement
│  └─ Task (PROJ-122c): Tests
│
└─ Story (PROJ-123): Tests & Docs
   ├─ Task (PROJ-123a): Integration tests
   └─ Task (PROJ-123b): Documentation
```

### Status Transitions

```
Epic/Story/Task:
TODO → IN PROGRESS → IN REVIEW → DONE

Git/PR aligned:
TODO           ← Before implementation starts
IN PROGRESS    ← Implementation in progress
IN REVIEW      ← Code review phase
DONE           ← PR merged to main
```

---

## ✨ PATTERN 1: Feature → Create Jira Epic

**Input:** Feature description

```
User: "Feature: Add date range filtering to reports API"
     └─ agent-orchestrator consults this skill
     └─ auto-create Epic + Stories in Jira
```

### Auto-create Epic

```javascript
async function createFeatureEpic(featureDescription) {
  // Extract key info
  const title = "Add date range filtering to reports API";
  const epic = {
    project: 'PROJ',
    issuetype: 'Epic',
    summary: title,
    description: featureDescription,
    priority: 'High',
    labels: ['feature', 'auto-created'],
    customFields: {
      'customfield_10000': title  // Epic name
    }
  };

  // Create Epic
  const epicResult = await jira.createIssue(epic);
  const epicKey = epicResult.key;  // e.g., PROJ-120
  console.log(`✅ Epic created: ${epicKey}`);

  return epicKey;
}
```

**Jira Result:**

```
PROJ-120: Epic "Add date range filtering to reports API"
├─ Status: TODO
├─ Description: [from feature description]
├─ Created by: agent-orchestrator
├─ Labels: feature, auto-created
└─ Assignee: (unassigned initially)
```

---

## 📖 PATTERN 2: Feature → Create Stories

Based on feature components:

```javascript
async function createStoriesForFeature(epicKey, featureDescription) {
  // Decompose feature into stories
  const stories = [
    {
      title: "API Endpoint - Implement date filtering",
      description: "Implement GET /api/v1/reports with date params",
      assignee: "backend-expert",
      points: 5
    },
    {
      title: "UI Component - Date picker",
      description: "Create date range picker UI component",
      assignee: "frontend-expert",
      points: 3
    },
    {
      title: "Tests & Documentation",
      description: "Add comprehensive tests and API documentation",
      assignee: "documentation-gen",
      points: 2
    }
  ];

  // Create each story
  const storyKeys = [];
  for (const story of stories) {
    const jiraStory = {
      project: 'PROJ',
      issuetype: 'Story',
      summary: story.title,
      description: story.description,
      parent: epicKey,
      customfields: {
        'customfield_10005': story.points  // Story points
      },
      assignee: story.assignee,
      labels: ['auto-created']
    };

    const result = await jira.createIssue(jiraStory);
    storyKeys.push(result.key);
    console.log(`✅ Story created: ${result.key}`);
  }

  return storyKeys;
}
```

**Jira Result:**

```
PROJ-120: Epic "Add date range filtering..."
├─ PROJ-121: Story "API Endpoint"
│  ├─ Status: TODO
│  ├─ Assignee: backend-expert
│  └─ Points: 5
│
├─ PROJ-122: Story "UI Component"
│  ├─ Status: TODO
│  ├─ Assignee: frontend-expert
│  └─ Points: 3
│
└─ PROJ-123: Story "Tests & Docs"
   ├─ Status: TODO
   ├─ Assignee: documentation-gen
   └─ Points: 2
```

---

## 🎯 PATTERN 3: Story → Link Commits

When code committed with Jira reference:

```
Commit message: "feat(reports): add date filter [PROJ-121]"
                                                  ^
                                            Jira reference
```

### Auto-link commit to Jira

```javascript
async function linkCommitToJira(commitSha, jiraRef) {
  // Add comment to Jira issue
  const comment = `
Commit linked: ${commitSha}

Message: [extracted from commit]
Author: [extracted from commit]
Date: [extracted from commit]

GitHub link: https://github.com/org/repo/commit/${commitSha}
`;

  await jira.addComment(jiraRef, comment);
  console.log(`✅ Linked commit ${commitSha} to ${jiraRef}`);
}
```

**Jira Result:**

```
PROJ-121: Story "API Endpoint"
└─ Comment from agent-orchestrator:
   "
   Commit linked: abc123def
   Message: feat(reports): add date filter
   Author: Backend-Expert
   ...
   "
```

---

## 🔗 PATTERN 4: PR Creation → Link to Stories

When PR created with Jira refs:

```javascript
async function linkPRToJiraStories(prNumber, jiraRefs) {
  // jiraRefs: ['PROJ-121', 'PROJ-122', 'PROJ-123']

  for (const ref of jiraRefs) {
    const comment = `
PR linked: #${prNumber}

Title: [extracted from PR]
Tests: [extracted from PR description]
Coverage: [extracted from PR description]

GitHub link: https://github.com/org/repo/pull/${prNumber}
`;

    await jira.addComment(ref, comment);
    console.log(`✅ Linked PR #${prNumber} to ${ref}`);
  }

  // Auto-transition stories to IN REVIEW
  for (const ref of jiraRefs) {
    await jira.transitionIssue(ref, 'IN REVIEW');
  }
}
```

**Jira Result:**

```
PROJ-121: Story "API Endpoint"
├─ Status: IN REVIEW (auto-transitioned)
└─ Comment from agent-orchestrator:
   "PR linked: #456"
   "Tests: 12/12 passing, Coverage: 100%"
```

---

## ✅ PATTERN 5: PR Merge → Close Stories

When PR merges to main:

```javascript
async function closeJiraStoriesOnMerge(mergedBranch, jiraRefs) {
  // jiraRefs: ['PROJ-121', 'PROJ-122', 'PROJ-123']

  for (const ref of jiraRefs) {
    // Add comment
    const comment = `
PR merged: Merged to main

Branch: ${mergedBranch}
Timestamp: [now]

Story is complete and in production.
`;
    await jira.addComment(ref, comment);

    // Transition to DONE
    await jira.transitionIssue(ref, 'DONE');
    
    console.log(`✅ Closed ${ref}: Merged to main`);
  }

  // Also close Epic if all stories done
  const epic = await jira.getIssue('PROJ-120');
  if (allStoriesDone(epic)) {
    await jira.transitionIssue('PROJ-120', 'DONE');
    console.log(`✅ Epic PROJ-120 closed: All stories complete`);
  }
}
```

**Jira Result:**

```
PROJ-120: Epic "Add date range filtering..."
├─ Status: DONE (auto-closed)
├─ PROJ-121: Story "API Endpoint"
│  └─ Status: DONE ✅
├─ PROJ-122: Story "UI Component"
│  └─ Status: DONE ✅
└─ PROJ-123: Story "Tests & Docs"
   └─ Status: DONE ✅
```

---

## 📝 REAL-TIME STATUS TRACKING

Auto-update Jira as work progresses:

```javascript
// When backend-expert starts coding
await jira.transitionIssue('PROJ-121', 'IN PROGRESS');

// When code is committed
await jira.addComment('PROJ-121', 'Code committed: abc123');

// When PR is created
await jira.addComment('PROJ-121', 'PR #456 created for review');
await jira.transitionIssue('PROJ-121', 'IN REVIEW');

// When PR is merged
await jira.addComment('PROJ-121', 'Merged to main, now in production');
await jira.transitionIssue('PROJ-121', 'DONE');
```

**Jira Timeline:**

```
PROJ-121: Story "API Endpoint"

Timeline:
├─ 10:00 AM: Created (agent-orchestrator)
├─ 10:05 AM: Assigned to backend-expert
├─ 11:00 AM: Status → IN PROGRESS
├─ 02:00 PM: Code committed (abc123)
├─ 02:30 PM: PR #456 created
├─ 02:30 PM: Status → IN REVIEW
├─ 03:00 PM: Code review approved
├─ 03:05 PM: PR merged to main
├─ 03:05 PM: Status → DONE ✅
└─ Activity: [All comments auto-posted]
```

---

## 🔐 PATTERN 6: Jira Status Synchronization

Keep Jira in sync with Git:

```javascript
async function syncJiraWithGit() {
  // Every 5 minutes, sync status

  // 1. Check for new commits
  const newCommits = await git.getCommitsSince(lastSync);
  for (const commit of newCommits) {
    if (commit.message.includes('[PROJ-')) {
      const ref = extractJiraRef(commit.message);
      await jira.addComment(ref, `Commit: ${commit.sha}`);
    }
  }

  // 2. Check for merged PRs
  const mergedPRs = await github.getMergedPRsSince(lastSync);
  for (const pr of mergedPRs) {
    if (pr.title.includes('[PROJ-')) {
      const ref = extractJiraRef(pr.title);
      await jira.transitionIssue(ref, 'DONE');
    }
  }

  // 3. Check for deleted branches
  const deletedBranches = await git.getDeletedBranchesSince(lastSync);
  // (similar sync)

  lastSync = now();
}

// Run every 5 minutes
setInterval(syncJiraWithGit, 5 * 60 * 1000);
```

---

## ⚠️ ERROR HANDLING

### Error: Jira issue not found

```
❌ Error: Issue PROJ-999 not found in Jira

Fix:
1. Verify correct project key (PROJ vs PROJX)
2. Verify issue exists in Jira UI
3. Check permissions: bot must have access
4. Retry creation instead of linking
```

### Error: Cannot transition status

```
❌ Error: Cannot transition PROJ-121 from TODO to IN REVIEW

Fix:
1. Check Jira workflow: are transitions allowed?
2. Check statuses: must follow workflow
3. May need intermediate transition (TODO → IN PROGRESS → IN REVIEW)
```

### Error: Jira API rate limit

```
❌ Error: API rate limit exceeded

Fix:
1. Wait and retry (exponential backoff)
2. Batch operations to reduce API calls
3. Increase rate limit in Jira instance settings
```

---

## 🎯 FULL WORKFLOW EXAMPLE

```
User: "Feature: Add date filtering"
  ↓
agent-orchestrator consults Jira-Integration-Patterns skill
  ↓
CREATE EPIC
PROJ-120: Epic "Add date range filtering..."
  ↓
CREATE STORIES
PROJ-121: Story "API Endpoint" → Assigned to backend-expert
PROJ-122: Story "UI Component" → Assigned to frontend-expert
PROJ-123: Story "Tests & Docs" → Assigned to documentation-gen
  ↓
backend-expert starts work
PROJ-121 Status: TODO → IN PROGRESS
  ↓
backend-expert completes code
Commit: "feat(reports): add date filter [PROJ-121]"
  ↓ (auto-link via MCP Git)
PROJ-121 Comment: "Commit linked: abc123def"
  ↓
PR created: #456
  ↓ (auto-link via MCP GitHub)
PROJ-121 Status: IN PROGRESS → IN REVIEW
PROJ-121 Comment: "PR #456 created"
  ↓
Code review approved
  ↓
PR merged to main
  ↓ (auto-transition via MCP Jira)
PROJ-121 Status: IN REVIEW → DONE
PROJ-120 Status: (all stories done) → DONE
  ↓
✅ FEATURE COMPLETE
   PROJ-120: DONE (closed)
   PROJ-121: DONE (closed)
   PROJ-122: DONE (closed)
   PROJ-123: DONE (closed)
```

---

## 🔒 SECURITY & PERMISSIONS

### Jira Credentials

```bash
# Store securely, NEVER in code
JIRA_HOST=yourcompany.atlassian.net
JIRA_EMAIL=bot@company.com
JIRA_API_TOKEN=<from Atlassian account settings>

# Agent must have permissions:
- Create issues
- Link issues
- Add comments
- Transition issues
- Update issue fields
```

### Audit Trail

```
Each auto-action logged:
- Timestamp
- Action (create/link/comment/transition)
- Jira key
- Result (success/error)
- User (agent-orchestrator)

Searchable in Jira activity feed
```

---

**Última actualización:** 2026-06-04
**Estándar:** Jira Cloud REST API v3
