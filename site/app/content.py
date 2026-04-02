"""Parse YAML frontmatter and load blog posts from site/posts/."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

import yaml

POSTS_DIR = Path(__file__).resolve().parent.parent / "posts"


@dataclass
class BlogPost:
    title: str
    date: datetime
    description: str
    body: str
    slug: str = ""
    image: str = ""
    tags: list[str] = field(default_factory=list)
    draft: bool = False
    author: str = ""


def parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    """Split ``---`` delimited YAML frontmatter from the markdown body."""
    if not text.startswith("---"):
        return {}, text
    _, fm, body = text.split("---", 2)
    return yaml.safe_load(fm) or {}, body.strip()


def _post_from_path(path: Path) -> BlogPost | None:
    meta, body = parse_frontmatter(path.read_text())
    if meta.get("draft", False):
        return None
    date = meta.get("date", datetime.min)
    if isinstance(date, str):
        date = datetime.fromisoformat(date)
    return BlogPost(
        title=meta.get("title", path.stem),
        date=date,
        description=meta.get("description", ""),
        body=body,
        slug=path.stem,
        image=meta.get("image", ""),
        tags=meta.get("tags", []),
        draft=False,
        author=meta.get("author", ""),
    )


def load_blog_posts() -> list[BlogPost]:
    """Load all non-draft blog posts, sorted by date descending."""
    posts: list[BlogPost] = []
    if not POSTS_DIR.exists():
        return posts
    for path in POSTS_DIR.glob("*.md"):
        post = _post_from_path(path)
        if post:
            posts.append(post)
    posts.sort(key=lambda p: p.date, reverse=True)
    return posts


def load_post_by_slug(slug: str) -> BlogPost | None:
    """Load a single post by its slug (filename without extension)."""
    path = POSTS_DIR / f"{slug}.md"
    if not path.exists():
        return None
    return _post_from_path(path)
