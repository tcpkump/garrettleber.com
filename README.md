# garrettleber.com

## Description

This repo holds the source code for my personal website, a static site built with Flask and [WebTUI](https://webtui.ironclad.sh/), frozen into static HTML via Frozen-Flask, and deployed to GitHub Pages.

## Site

The site (`site/`) is a Flask application that renders HTML using Jinja2 templates styled with WebTUI. Blog posts are written in Markdown under `site/posts/`. At build time, Frozen-Flask crawls all routes and outputs a fully static site to `site/build/`.

**Stack:**
- [Flask](https://flask.palletsprojects.com/) — web framework
- [WebTUI](https://webtui.ironclad.sh/) — terminal-aesthetic CSS framework
- [Frozen-Flask](https://frozen-flask.readthedocs.io/) — static site generator
- [uv](https://docs.astral.sh/uv/) — Python package manager

### Local development

A Nix dev shell is provided with Python, uv, and pre-commit:

```sh
nix develop
```

To run the dev server:

```sh
uv run --project site/ flask --app app run
```

To build the static site:

```sh
bash scripts/build-site.sh
```

Output is written to `site/build/`.

## CI/CD

GitHub Actions builds the static site on every push to `main` that touches `site/` and deploys it to GitHub Pages. The build uses the Nix flake (`flake.nix`) to ensure a reproducible environment.
