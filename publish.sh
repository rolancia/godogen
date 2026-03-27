#!/usr/bin/env bash
# Publish godogen skills into a target project directory.
# Creates .agents/skills/ and copies an AGENTS.md.
#
# Usage: ./publish.sh <target_dir> [agents_md]
#   agents_md  Path to the AGENTS.md template to use (default: game.md)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <target_dir> [agents_md]"
    exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd || (mkdir -p "$1" && cd "$1" && pwd))"
AGENTS_MD="${2:-$REPO_ROOT/game.md}"

echo "Publishing to: $TARGET"

mkdir -p "$TARGET/.agents/skills"
rsync -a --delete --exclude='doc_source/' --exclude='__pycache__/' \
    "$REPO_ROOT/skills/" "$TARGET/.agents/skills/"

cp "$AGENTS_MD" "$TARGET/AGENTS.md"
echo "Created AGENTS.md (from $AGENTS_MD)"

if [ ! -f "$TARGET/.gitignore" ]; then
    cat > "$TARGET/.gitignore" << 'GI_EOF'
assets
screenshots
.godot
*.import
GI_EOF
    echo "Created .gitignore"
fi

git -C "$TARGET" init -q 2>/dev/null || true

echo "Done. skills: $(ls "$TARGET/.agents/skills/" | wc -l)"
