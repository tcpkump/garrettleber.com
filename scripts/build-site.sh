#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

uv run --project "$REPO_ROOT/site/" python "$REPO_ROOT/site/freeze.py"
