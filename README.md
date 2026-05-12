# garrettleber.com

## Description

This repo holds the source code for my personal website, a static site built with Flask, frozen into static HTML via Frozen-Flask, and deployed to GitHub Pages.

## Site

The site (`site/`) is a Flask application that renders HTML using Jinja2 templates. Blog posts are written in Markdown under `site/posts/`. At build time, Frozen-Flask crawls all routes and outputs a fully static site to `site/build/`.

**Stack:**
- [Flask](https://flask.palletsprojects.com/) — web framework
- [Frozen-Flask](https://frozen-flask.readthedocs.io/) — static site generator
- [uv](https://docs.astral.sh/uv/) — Python package manager

### Creating a new blog post

Use the helper script to scaffold a new post with the current timestamp:

```sh
bash scripts/new-post.sh my-post-slug
```

This creates `site/posts/my-post-slug.md` with frontmatter pre-filled and `draft: true`. The slug (filename without `.md`) becomes the URL path under `/blog/`. Fill in the `title` and `description`, add your content, then set `draft: false` when ready to publish.

### Local development

A Nix dev shell is provided with Python, uv, and pre-commit:

```sh
nix develop
```

To run the dev server:

```sh
uv run --project site/ flask --app app run --debug
```

To build the static site:

```sh
bash scripts/build-site.sh
```

Output is written to `site/build/`.

## CI/CD

GitHub Actions builds the static site on every push to `main` that touches `site/` and deploys it to GitHub Pages. The build uses the Nix flake (`flake.nix`) to ensure a reproducible environment.
