#!/bin/bash
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || pwd)}"
MARKETPLACES_FILE="$PROJECT_DIR/.claude/marketplaces.txt"
SKILLS_REPOS_DIR="$HOME/.claude/skills-repos"
SKILLS_DIR="$HOME/.claude/skills"

usage() {
  echo "Usage:"
  echo "  plugin.sh marketplace add <github-user>/<repo>"
  echo "  plugin.sh install <skill-name>"
  exit 1
}

marketplace_slug() {
  local repo="$1"
  echo "$repo" | tr '/' '-'
}

ensure_marketplace_cloned() {
  local repo="$1"
  local slug
  slug=$(marketplace_slug "$repo")
  local repo_dir="$SKILLS_REPOS_DIR/$slug"

  if [ -d "$repo_dir/.git" ]; then
    echo "Updating $repo..."
    git -C "$repo_dir" pull --ff-only origin main 2>/dev/null || \
      git -C "$repo_dir" pull --ff-only origin master 2>/dev/null || true
  else
    echo "Cloning $repo..."
    mkdir -p "$SKILLS_REPOS_DIR"
    git clone --depth=1 "https://github.com/$repo.git" "$repo_dir"
  fi
}

link_all_skills() {
  local repo="$1"
  local slug
  slug=$(marketplace_slug "$repo")
  local repo_dir="$SKILLS_REPOS_DIR/$slug"

  if [ -f "$repo_dir/scripts/link-skills.sh" ]; then
    bash "$repo_dir/scripts/link-skills.sh"
  else
    # Fallback: link any subdirectory that contains a prompt.md or skill.md
    mkdir -p "$SKILLS_DIR"
    for skill_dir in "$repo_dir"/*/; do
      if [ -f "$skill_dir/prompt.md" ] || [ -f "$skill_dir/skill.md" ]; then
        local skill_name
        skill_name=$(basename "$skill_dir")
        ln -sf "$skill_dir" "$SKILLS_DIR/$skill_name" 2>/dev/null || true
        echo "  Linked $skill_name"
      fi
    done
  fi
}

cmd_marketplace_add() {
  local repo="${1:-}"
  if [ -z "$repo" ] || [[ "$repo" != */* ]]; then
    echo "Error: expected <github-user>/<repo>, got: '$repo'"
    usage
  fi

  touch "$MARKETPLACES_FILE"

  if grep -qxF "$repo" "$MARKETPLACES_FILE" 2>/dev/null; then
    echo "Marketplace '$repo' is already registered."
    return 0
  fi

  echo "$repo" >> "$MARKETPLACES_FILE"
  echo "Registered marketplace: $repo"

  ensure_marketplace_cloned "$repo"
  link_all_skills "$repo"
  echo "Done. Skills from '$repo' are now available."
}

cmd_install() {
  local skill_name="${1:-}"
  if [ -z "$skill_name" ]; then
    echo "Error: skill name required"
    usage
  fi

  if [ ! -f "$MARKETPLACES_FILE" ]; then
    echo "No marketplaces registered. Run: plugin.sh marketplace add <user>/<repo>"
    exit 1
  fi

  local found=false
  while IFS= read -r repo || [ -n "$repo" ]; do
    [[ "$repo" =~ ^#.*$ || -z "$repo" ]] && continue

    local slug
    slug=$(marketplace_slug "$repo")
    local repo_dir="$SKILLS_REPOS_DIR/$slug"

    ensure_marketplace_cloned "$repo"

    # Look for skill by name in this marketplace
    local skill_dir=""
    for candidate in "$repo_dir/$skill_name" "$repo_dir/skills/$skill_name"; do
      if [ -d "$candidate" ]; then
        skill_dir="$candidate"
        break
      fi
    done

    # Also search subdirectories (skills may be nested)
    if [ -z "$skill_dir" ]; then
      skill_dir=$(find "$repo_dir" -maxdepth 3 -type d -name "$skill_name" 2>/dev/null | head -1 || true)
    fi

    if [ -n "$skill_dir" ]; then
      mkdir -p "$SKILLS_DIR"
      ln -sf "$skill_dir" "$SKILLS_DIR/$skill_name"
      echo "Installed skill '$skill_name' from $repo"
      found=true
      break
    fi
  done < "$MARKETPLACES_FILE"

  if [ "$found" = false ]; then
    echo "Skill '$skill_name' not found in any registered marketplace."
    echo "Registered marketplaces:"
    cat "$MARKETPLACES_FILE"
    exit 1
  fi
}

# --- main ---

subcommand="${1:-}"
shift || true

case "$subcommand" in
  marketplace)
    action="${1:-}"
    shift || true
    case "$action" in
      add) cmd_marketplace_add "$@" ;;
      *) echo "Unknown marketplace action: '$action'"; usage ;;
    esac
    ;;
  install)
    cmd_install "$@"
    ;;
  *)
    echo "Unknown command: '$subcommand'"
    usage
    ;;
esac
