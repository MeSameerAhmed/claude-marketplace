#!/usr/bin/env bash
# Manual install for environments that don't use the Claude Code plugin system.
# Copies the command + subagents into ~/.claude/.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_CMD="$HOME/.claude/commands"
DEST_AGT="$HOME/.claude/agents"

mkdir -p "$DEST_CMD" "$DEST_AGT"

cp -v "$HERE/commands/implement-with-review.md" "$DEST_CMD/"
cp -v "$HERE/agents/opus-architect.md"          "$DEST_AGT/"
cp -v "$HERE/agents/pr-reviewer.md"             "$DEST_AGT/"

echo
echo "Installed. In Claude Code, run /implement-with-review to use it."
