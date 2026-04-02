"""Freeze the Flask app into a static site under build/."""

from flask_frozen import Freezer

from app import create_app
from app.content import load_blog_posts

app = create_app()
app.config["FREEZER_DESTINATION"] = "build"
app.config["FREEZER_RELATIVE_URLS"] = True

freezer = Freezer(app)


@freezer.register_generator
def blog_post():
    for post in load_blog_posts():
        yield "main.blog_post", {"slug": post.slug}


if __name__ == "__main__":
    freezer.freeze()
    print("Static site built in site/build/")
