#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SKILLS_REPO_DIR="$HOME/.claude/skills-repos/mattpocock-skills"

if [ -d "$SKILLS_REPO_DIR/.git" ]; then
  git -C "$SKILLS_REPO_DIR" pull --ff-only origin main 2>/dev/null || true
else
  mkdir -p "$(dirname "$SKILLS_REPO_DIR")"
  git clone --depth=1 https://github.com/mattpocock/skills.git "$SKILLS_REPO_DIR"
fi

bash "$SKILLS_REPO_DIR/scripts/link-skills.sh"
