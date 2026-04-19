#!/usr/bin/env bash
# Rebase current branch to latest ChordPro/chordpro:dev
# Usage: bash script/rebase-to-dev.sh
set -e

UPSTREAM_REMOTE="upstream"
UPSTREAM_BRANCH="dev"

echo "Fetching ${UPSTREAM_REMOTE}..."
git fetch "${UPSTREAM_REMOTE}"

echo "Rebasing onto ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}..."
git rebase "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"

echo "Done. $(git log --oneline "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}..HEAD" | wc -l | tr -d ' ') commits on top of upstream/dev."
