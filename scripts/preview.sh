#!/usr/bin/env bash
# Preview the blog locally before pushing to GitHub.
# Works on macOS (Terminal) and Windows (Git Bash).
#
# Usage:
#   ./scripts/preview.sh            # live preview at http://localhost:4000 (auto-reloads on save)
#   ./scripts/preview.sh --drafts   # also show posts in _drafts/ and future-dated posts
#   ./scripts/preview.sh --build    # one-off build into _site/ (what GitHub Pages will produce)
#   ./scripts/preview.sh --port 4001  # use another port

set -euo pipefail

# Always run from the repo root, wherever the script is called from
cd "$(dirname "$0")/.."

PORT=4000
MODE=serve
EXTRA=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --drafts) EXTRA+=(--drafts --future) ;;
    --build)  MODE=build ;;
    --port)   PORT="$2"; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)"; exit 1 ;;
  esac
  shift
done

if ! command -v bundle >/dev/null 2>&1; then
  echo "Ruby/Bundler not found. Install Ruby first (see README: Local preview)."
  exit 1
fi

# Install gems only when something is missing
bundle check >/dev/null 2>&1 || bundle install

if [[ "$MODE" == build ]]; then
  bundle exec jekyll build ${EXTRA[@]+"${EXTRA[@]}"}
  echo "Built into _site/"
else
  echo "Preview: http://localhost:$PORT  (Ctrl+C to stop)"
  bundle exec jekyll serve --livereload --port "$PORT" ${EXTRA[@]+"${EXTRA[@]}"}
fi
