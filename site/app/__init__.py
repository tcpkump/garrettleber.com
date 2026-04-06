"""Flask app factory for garrettleber.com site."""

from flask import Flask


def create_app() -> Flask:
    app = Flask(__name__, static_url_path="")

    from app.routes import bp

    app.register_blueprint(bp)

    return app
