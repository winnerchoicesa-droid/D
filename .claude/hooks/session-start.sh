#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MARKETPLACES_FILE="$PROJECT_DIR/.claude/marketplaces.txt"
SKILLS_REPOS_DIR="$HOME/.claude/skills-repos"

marketplace_slug() {
  echo "$1" | tr '/' '-'
}

sync_marketplace() {
  local repo="$1"
  local slug
  slug=$(marketplace_slug "$repo")
  local repo_dir="$SKILLS_REPOS_DIR/$slug"

  if [ -d "$repo_dir/.git" ]; then
    git -C "$repo_dir" pull --ff-only origin main 2>/dev/null || \
      git -C "$repo_dir" pull --ff-only origin master 2>/dev/null || true
  else
    mkdir -p "$SKILLS_REPOS_DIR"
    git clone --depth=1 "https://github.com/$repo.git" "$repo_dir"
  fi

  if [ -f "$repo_dir/scripts/link-skills.sh" ]; then
    bash "$repo_dir/scripts/link-skills.sh"
  else
    mkdir -p "$HOME/.claude/skills"
    for skill_dir in "$repo_dir"/*/; do
      if [ -f "$skill_dir/prompt.md" ] || [ -f "$skill_dir/skill.md" ]; then
        ln -sf "$skill_dir" "$HOME/.claude/skills/$(basename "$skill_dir")" 2>/dev/null || true
      fi
    done
  fi
}

if [ ! -f "$MARKETPLACES_FILE" ]; then
  exit 0
fi

while IFS= read -r repo || [ -n "$repo" ]; do
  [[ "$repo" =~ ^#.*$ || -z "$repo" ]] && continue
  sync_marketplace "$repo"
done < "$MARKETPLACES_FILE"
