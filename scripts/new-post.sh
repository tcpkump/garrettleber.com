#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/new-post.sh <slug>
# Example: scripts/new-post.sh my-new-post

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <slug>" >&2
    echo "Example: $0 my-new-post" >&2
    exit 1
fi

SLUG="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POST_FILE="$REPO_ROOT/site/posts/${SLUG}.md"

if [[ -e "$POST_FILE" ]]; then
    echo "Error: $POST_FILE already exists" >&2
    exit 1
fi

DATE="$(date +%Y-%m-%dT%H:%M:%S%z)"

cat > "$POST_FILE" <<EOF
---
title: ""
date: ${DATE}
socialShare: false
draft: true
author: "Garrett Leber"
tags: []
image: ""
description: ""
---

EOF

echo "Created $POST_FILE"
