#!/usr/bin/env bash
# Sync Sidekik docs from this repo (sidekik-docs) into local clones of the code repos.
#
# Usage:
#   ./scripts/sync-docs.sh <parent-dir> [--force] [--only sidekik-gateway,sidekik-tutor] [--dry-run]
#
#   <parent-dir>  folder that contains your clones, e.g. ~/code  (with ~/code/sidekik-gateway, ...)
#   --force       also overwrite CLAUDE.md and .env.example (normally only created if missing)
#   --only        comma-separated repo names to sync (default: every repo found in <parent-dir>)
#   --dry-run     print what would change, write nothing
#
# Always overwritten in each code repo:  docs/ARCHITECTURE.md, docs/SCHEMA.md, docs/DESIGN.md,
#                                        docs/KICKOFF.md, docs/LOVABLE_PROMPTS.md (web only)
# Created only if missing (unless --force): CLAUDE.md, .env.example
set -euo pipefail

DOCS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="${1:-}"; shift || true
FORCE=0; ONLY=""; DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --only) ONLY="${2:-}"; shift ;;
    --dry-run) DRY=1 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ -z "$PARENT" || ! -d "$PARENT" ]]; then
  echo "Usage: $0 <parent-dir-with-your-repo-clones> [--force] [--only a,b] [--dry-run]" >&2
  exit 2
fi
PARENT="$(cd "$PARENT" && pwd)"

copy() { # copy <src> <dst> <mode: always|ifmissing>
  local src="$1" dst="$2" mode="$3"
  if [[ "$mode" == "ifmissing" && -e "$dst" && $FORCE -eq 0 ]]; then
    echo "    skip   ${dst#$PARENT/} (exists; use --force to overwrite)"; return
  fi
  if [[ -e "$dst" ]] && cmp -s "$src" "$dst"; then
    echo "    same   ${dst#$PARENT/}"; return
  fi
  echo "    write  ${dst#$PARENT/}"
  if [[ $DRY -eq 0 ]]; then mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; fi
}

synced=0
for spec in "$DOCS_ROOT"/repos/sidekik-*; do
  name="$(basename "$spec")"
  if [[ -n "$ONLY" && ",$ONLY," != *",$name,"* ]]; then continue; fi
  target="$PARENT/$name"
  if [[ ! -d "$target" ]]; then
    [[ -n "$ONLY" ]] && echo "!! $name: no clone at $target" >&2
    continue
  fi
  echo "==> $name"
  copy "$DOCS_ROOT/ARCHITECTURE.md" "$target/docs/ARCHITECTURE.md" always
  copy "$DOCS_ROOT/SCHEMA.md"       "$target/docs/SCHEMA.md"       always
  for f in "$spec"/docs/*.md; do
    copy "$f" "$target/docs/$(basename "$f")" always
  done
  copy "$spec/CLAUDE.md"    "$target/CLAUDE.md"    ifmissing
  copy "$spec/.env.example" "$target/.env.example" ifmissing
  synced=$((synced + 1))
done

if [[ $synced -eq 0 ]]; then
  echo "No sidekik-* clones found in $PARENT. Clone your repos there first." >&2
  exit 1
fi
echo "Done: $synced repo(s). Review with 'git status' in each repo, then commit (e.g. 'docs: sync from sidekik-docs')."
[[ $DRY -eq 1 ]] && echo "(dry run: nothing was written)"
exit 0
