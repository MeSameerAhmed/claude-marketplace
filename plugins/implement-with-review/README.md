# implement-with-review

End-to-end feature workflow plugin for [Claude Code](https://claude.com/claude-code):

```
spec  →  plan  →  implement  →  branch + commit + PR  →  reviewer subagent
                                                          ↑           ↓
                                                          └─ fix ─────┘  (up to 3 rounds)
                                                                ↓
                                                            APPROVE + build + summary
```

Invoke with:

```
/implement-with-review <feature description, ticket link, or rough idea>
```

## Contents

| File | Purpose |
|------|---------|
| `commands/implement-with-review.md` | The `/implement-with-review` slash command. Orchestrates all phases. |
| `agents/opus-architect.md` | Optional planning subagent (Opus). Used when the user picks "Opus" at the model-selection prompt. |
| `agents/pr-reviewer.md` | Reviewer subagent. Posts inline review comments on the PR, returns JSON the orchestrator uses to drive fixes. Supports Redmine PRD fetching. |

## Requirements

- **Claude Code** installed.
- **`gh` CLI** authenticated against the repo you'll work in (`gh auth status`).
- **`git`** configured with push access.
- **Java/Maven** if you want the `mvn pmd:check` and `mvn clean install -DskipTests` steps to run as-is. The command is Maven-flavoured in PHASE 3 (PMD) and PHASE 4 (build). Adapt for your stack if you're not on Java.
- **Optional:** Redmine MCP server, if you want the reviewer to auto-fetch a PRD from a Redmine ticket URL or ID pasted in the prompt.

## Install

### Via marketplace (recommended)

```
/plugin marketplace add MeSameerAhmed/claude-marketplace
/plugin install implement-with-review
```

### Manual (fallback)

```bash
./install.sh
```

This copies the command and subagents into `~/.claude/commands/` and `~/.claude/agents/`.

## Usage

```
/implement-with-review Add a /health endpoint that returns the build SHA and uptime
```

1. You'll be asked **Sonnet or Opus for planning?** Implementation and review always run on Sonnet.
2. The command builds a spec, asks at most one round of clarifying questions, prints the plan.
3. Reply `ok` to approve. It implements, commits, pushes, opens a PR, and spawns the reviewer.
4. Up to 3 review rounds run automatically. Fixes are applied between each round.
5. On approval, the pending review is submitted as APPROVE and a final summary is printed.

### With a Redmine ticket

Paste a Redmine ticket URL or ID in the description and the reviewer will fetch the full
ticket + all comments via the Redmine MCP and use it as the PRD for compliance checks.
Requires the Redmine MCP server to be configured for your Redmine instance.

## Customising for non-Java stacks

Edit `commands/implement-with-review.md`:

- **PHASE 3** fix-commit fallback runs `mvn pmd:check`. Replace with your linter (`npm run lint`, `cargo clippy`, `ruff check`, etc.).
- **PHASE 4** runs `mvn clean install -DskipTests`. Replace with your build (`npm run build`, `cargo build`, `go build ./...`, etc.).

Everything else is stack-agnostic.
