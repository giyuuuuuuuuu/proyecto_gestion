"""Aplicación Flask — mini gestor de tareas."""
import os

from dotenv import load_dotenv
from flask import Flask

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "dev-only-change-me")


@app.route("/")
def index():
    return "Proyecto gestión — Fase 0 lista. Siguiente: Fase 1 (plantillas).", 200


if __name__ == "__main__":
    app.run(debug=True, port=5000)
