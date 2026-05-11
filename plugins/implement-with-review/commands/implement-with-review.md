---
allowedTools:
  - Agent
  - AskUserQuestion
  - Bash(gh *)
  - Bash(git *)
  - Bash(mvn *)
  - Bash(cat /tmp/*)
  - Bash(rm /tmp/*)
  - Read
  - Read(/tmp/*)
  - Write
  - Write(/tmp/*)
  - Edit
  - Glob
  - Grep
blockedTools:
  - EnterPlanMode
---

Implement the following feature using the full PR review loop workflow:

$ARGUMENTS

---

### PRE-PHASE — MODEL SELECTION

**Do this first, before anything else.**

Ask the user exactly this:

> Which model for **planning**?
> **[1] Sonnet** *(default — faster)* or **[2] Opus** *(more thorough, slower)*?
>
> *(Implementation, PR review, and all other phases always run on Sonnet.)*

Wait for their reply:
- `"2"` / `"opus"` / `"o"` → `PLAN_MODEL=opus`
- Anything else (blank, `"1"`, `"sonnet"`, `"s"`) → `PLAN_MODEL=sonnet`

**If `PLAN_MODEL=sonnet`** → proceed to **PHASE 0** below as normal.

**If `PLAN_MODEL=opus`** → skip PHASE 0 and PHASE 1 entirely. Instead:

1. Announce: "Using Opus for planning — spawning architect…"
2. Spawn the `opus-architect` sub-agent with prompt: `"$ARGUMENTS"`
3. Parse the returned `<SPEC>…</SPEC>` and `<PLAN>…</PLAN>` blocks.
4. Present to the user:

   ```
   ## Spec (via Opus)

   {spec contents}

   ## Implementation Plan (via Opus)

   {plan contents}

   ---
   Reply **ok** to implement, or describe any changes.
   ```

5. Wait for reply:
   - `"ok"` / `"yes"` / `"go"` / `"lgtm"` → implement the plan directly (no plan mode — Opus already did the planning). Jump to **PHASE 2** after implementation.
   - User edits → incorporate changes, then implement. Jump to **PHASE 2** after implementation.

---

### PHASE 0 — PROMPT ENHANCEMENT

Before doing anything else, act as a prompt engineer to turn the raw input above into a
professional engineering spec. Do this silently first, then present it once.

**Step 1 — Silent context gathering (no output):**
- Run `git log --oneline -5` to infer branch naming conventions and recent work scope
- Scan `CLAUDE.md` (already in context) for relevant modules, tech stack, and conventions
- Grep for any class/method/file names mentioned in `$ARGUMENTS` to find related code

**Step 2 — Print the enhanced spec (exactly this format):**

```
## 📋 Feature Spec

**Goal:** <one sentence — what this does and why>

**Scope:**
- Module(s): <e.g. core › enterpriseService › notifications>
- Files likely touched: <best-guess list based on codebase scan>

**Acceptance criteria:**
- <criterion 1>
- <criterion 2>
- <add more as needed>

**Out of scope:** <anything obviously excluded or not needed>

**Open questions:** <max 2 genuinely ambiguous points — omit section entirely if none>
```

**Step 3 — Ask questions if genuinely necessary (before finalising the spec):**

If there are gaps that **cannot be reasonably inferred** from the codebase, ask them now — before
presenting the spec. Rules for asking:
- Only ask what is **truly blocking** — things that would lead to building the wrong thing entirely
- Infer aggressively first; only ask when inference would be a guess with major consequences
- Group all necessary questions into **one single message** — never ask in multiple rounds
- If nothing is blocking, skip this step entirely and go straight to Step 4

**Step 4 — Present the spec:**

> Spec above ↑ — reply **"ok"** to proceed, or describe any changes.

Wait for reply, then:
- `"ok"` / `"yes"` / `"go"` / `"lgtm"` → proceed immediately to PHASE 1 with the spec as requirement
- User edits → incorporate changes, proceed to PHASE 1

**Rules:**
- If `$ARGUMENTS` is already detailed, just structure and polish it; don't invent new requirements
- The spec must be scannable in 10 seconds — keep it tight
- Never ask questions that are "nice to know" — only ask if the answer changes what gets built

---

## Workflow to follow exactly

> **CRITICAL: This workflow has 4 phases. You MUST run ALL of them in sequence.**
> Do NOT pause, summarise, or wait for input between phases unless a phase explicitly says "wait for reply".
> Completing implementation (PHASE 1) is NOT the end — you MUST continue through PHASE 2 (PR), PHASE 3 (review loop), and PHASE 4 (summary).
> **If you stop after implementation without creating a PR and running the review loop, the workflow has FAILED.**
> Do NOT use EnterPlanMode anywhere in this workflow — it breaks the multi-phase flow.

### PHASE 1 — PLAN & IMPLEMENT

> **WARNING: Do NOT use EnterPlanMode.** Plan mode breaks the multi-phase flow.
> Instead, do inline planning as described below.

**Step 1 — Explore the codebase** (silent — no output):
- Use Glob, Grep, and Read to find all files relevant to the feature
- Understand existing patterns, service classes, repositories, controllers in the target domain
- Identify every file that needs changes

**Step 2 — Present the plan:**
```
## Implementation Plan

### Files to change
1. `path/to/File.java` — what to add/modify
2. `path/to/Other.java` — what to add/modify

### Steps
1. <specific step>
2. <specific step>

---
Reply **ok** to implement, or describe changes.
```

**Step 3 — Wait for approval**, then implement the plan fully.

**PHASE 1 ends the moment the last source file is written/edited.**
- Do NOT run the build, do NOT run PMD, do NOT print a summary or completion message.
- Any verification steps in the approved plan are deferred — skip them entirely here.
- The very next action after the last file edit MUST be `git checkout -b …` in PHASE 2.
- **Do NOT stop here. PHASE 2 is next. Keep going.**

### PHASE 2 — BRANCH, COMMIT & PR ← YOU MUST REACH THIS PHASE

**Run this immediately after the last file edit — no summary, no pause, no "done" message:**

1. Create a feature branch:
   ```bash
   git checkout -b <ticket_or_slug>
   ```
2. Stage only the files you changed and commit:
   ```bash
   git add <specific files>
   git commit -m "<type>: <description>"
   ```
3. Push and create the PR:
   ```bash
   git push -u origin HEAD
   gh pr create --title "<title>" --body "<body describing what and why>"
   ```
4. Capture context for the loop:
   ```bash
   PR_N=$(gh pr view --json number --jq '.number')
   OWNER=$(gh repo view --json owner --jq '.owner.login')
   REPO=$(gh repo view --json name --jq '.name')
   ```

Announce: "PR #$PR_N created. Starting review loop."

**Immediately proceed to PHASE 3. Do not stop.**

### PHASE 3 — REVIEW LOOP

Track: `ROUND=1`, `REVIEW_ID=""`, `PREV_ISSUES=[]`, `MAX_ROUNDS=3`.

Repeat until `decision == "APPROVED"` or `ROUND > MAX_ROUNDS`:

**3a.** Announce: "Review round $ROUND — spawning pr-reviewer on PR #$PR_N …"

**3b.** Spawn the pr-reviewer sub-agent:
- subagent_type: `"pr-reviewer"`
- **Round 1 prompt** (full review):
  ```
  Review PR #$PR_N
  ```
- **Round 2+ prompt** (fix verification only — include previous issues so reviewer ONLY checks fixes):
  ```
  Re-review PR #$PR_N. ONLY verify these previously flagged issues are fixed:
  PREVIOUS_ISSUES: $PREV_ISSUES_JSON
  Do NOT perform a full review. Only check fixes and flag if a fix introduced obviously broken new code.
  ```
  Where `$PREV_ISSUES_JSON` is the JSON array of issues from the previous round.

**3c.** Parse the returned JSON from the sub-agent output:
```
REVIEW_ID  = result.review_id
decision   = result.decision
issues     = result.issues         ← list of {file, line, description, fix}
pr_summary = result.pr_changes_summary
```

**3d.** If `decision == "APPROVED"` → exit loop.

**3e.** If `ROUND == MAX_ROUNDS` and `decision != "APPROVED"`:
- Announce: "⚠️ Safety cap reached ($MAX_ROUNDS rounds). Force-approving with remaining notes."
- Set `decision = "APPROVED"` and exit loop. The pending review will be submitted as-is.
- In the PHASE 4 summary, note that approval was forced after max rounds.

**3f.** If `decision == "REQUEST_CHANGES"`:
- Save `PREV_ISSUES = issues` (this will be passed to the next round's reviewer prompt)
- For each item in `issues`:
  - Read `file`, understand the context around `line`
  - Apply the minimal correct fix described in `fix`
- Stage all fixed files: `git add <files>`
- Attempt commit: `git commit -m "fix: <description>"`
- **If the pre-commit hook fails due to PMD violations:**
  1. Run `mvn pmd:check` to list all violations.
  2. Fix ONLY violations that require **no business logic changes**:
     - ✅ Safe to fix: unused imports, redundant field initializers, missing
       braces, empty catch blocks (add a comment), unnecessary modifiers,
       missing `@Override`, diamond operator, local variable naming
     - ❌ Do NOT fix: cyclomatic complexity, God class, too many methods,
       long method, data class, public API renaming, return empty instead
       of null (callers may depend on null checks)
  3. Stage the safe fixes: `git add <files>`
  4. Commit bypassing the hook: `git commit -n -m "fix: <description> (PMD structural violations skipped)"`
- Push all fix commits:
  ```bash
  git push
  ```
- Announce: "Round $ROUND fixes pushed. Re-invoking reviewer for fix verification…"
- `ROUND++` → go back to 3a.

### PHASE 4 — SUBMIT & SUMMARISE

Once the loop exits with APPROVED:

1. Submit the existing pending review as approved using `REVIEW_ID` from the last round:
   ```bash
   gh api repos/$OWNER/$REPO/pulls/$PR_N/reviews/$REVIEW_ID/events \
     --method POST -f event=APPROVE -f body="All issues resolved. LGTM!"
   ```

2. Run the build to verify the final state:
   ```bash
   mvn clean install -DskipTests 2>&1 | tail -20
   ```

3. Print the final summary (this is the ONLY place a summary is printed):
   ```
   ## Summary of Changes
   <bullet per item in pr_summary from last review result>

   ## Build
   <SUCCESS or FAILED — from step 2>

   ## PR
   <gh pr view $PR_N --json url --jq '.url'>

   Approved after $ROUND review round(s).
   ```
