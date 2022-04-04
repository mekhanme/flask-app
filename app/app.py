from flask import Flask, render_template, redirect, url_for, request
from prometheus_flask_exporter import PrometheusMetrics
from logging.config import dictConfig
from flask_healthz import healthz
from flask_healthz import HealthError
import requests
import contentful
import time
import os
# import flask-markdown2
# import markdown2

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://flask.logging.wsgi_errors_stream',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

CONTENTFUL_SPACE_ID = os.environ['CONTENTFUL_SPACE_ID']
CONTENTFUL_ACEESS_TOKEN = os.environ['CONTENTFUL_ACEESS_TOKEN']

app = Flask(__name__)
metrics = PrometheusMetrics(app)

app.register_blueprint(healthz, url_prefix="/healthz")
metrics.info('app_info', 'Application info', version='1.0.3')

def check_cdn():
    requests.get('https://cdn.contentful.com')

def printok():
    print("Everything is ok")

def liveness():
    try:
        printok()
    except Exception:
        raise HealthError("Not ready")

def readiness():
    try:
        check_cdn()
    except Exception:
        raise HealthError("Not ready")

app.config.update(
    HEALTHZ = {
        "live": "app.liveness",
        "ready": "app.readiness",
    }
)

@app.route('/')
def index():
    CONTENTFUL_SITE_ENTRY_ID = os.environ['CONTENTFUL_SITE_ENTRY_ID']

    client = contentful.Client(CONTENTFUL_SPACE_ID, CONTENTFUL_ACEESS_TOKEN)
    entry = client.entry(CONTENTFUL_SITE_ENTRY_ID)
    content = entry.content

    return render_template('index.html', content=content)

@app.route('/me')
def me():
    CONTENTFUL_ABOUT_ENTRY_ID = os.environ['CONTENTFUL_ABOUT_ENTRY_ID']

    client = contentful.Client(CONTENTFUL_SPACE_ID, CONTENTFUL_ACEESS_TOKEN)
    entry = client.entry(CONTENTFUL_ABOUT_ENTRY_ID)
    content = entry.content

    return render_template('me.html', content=content)

@app.route('/tools')
def tools():
    CONTENTFUL_TOOLS_ENTRY_ID = os.environ['CONTENTFUL_TOOLS_ENTRY_ID']

    client = contentful.Client(CONTENTFUL_SPACE_ID, CONTENTFUL_ACEESS_TOKEN)
    entry = client.entry(CONTENTFUL_TOOLS_ENTRY_ID)
    content = entry.content
    ip = request.environ.get('HTTP_X_REAL_IP', request.remote_addr)
    app.logger.info('ip: ' + ip)

    return render_template('tools.html', ip=ip, content=content)

metrics.register_default(
    metrics.counter(
        'by_path_counter', 'Request count by request paths',
        labels={'path': lambda: request.path}
    )
)

if __name__ == '__main__':
    app.run()

