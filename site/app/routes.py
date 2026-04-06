"""Routes: /, /blog, /blog/<slug>."""

from flask import Blueprint, abort, render_template
from markdown import markdown

from app.content import load_blog_posts, load_post_by_slug

bp = Blueprint("main", __name__)

MD_EXTENSIONS = ["fenced_code", "codehilite", "toc", "tables"]
MD_EXT_CONFIGS = {
    "codehilite": {"css_class": "highlight", "guess_lang": False},
    "toc": {"permalink": True},
}


@bp.route("/")
def home():
    return render_template("home.html")


@bp.route("/blog/")
def blog_list():
    posts = load_blog_posts()
    return render_template("blog_list.html", posts=posts)


@bp.route("/blog/<slug>/")
def blog_post(slug: str):
    post = load_post_by_slug(slug)
    if post is None:
        abort(404)
    html_body = markdown(
        post.body,
        extensions=MD_EXTENSIONS,
        extension_configs=MD_EXT_CONFIGS,
    )
    return render_template("blog_post.html", post=post, content=html_body)
