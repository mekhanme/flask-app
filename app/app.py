from flask import Flask, render_template, redirect, url_for, request
from prometheus_flask_exporter import PrometheusMetrics
import contentful
import os
# import flask-markdown2
# import markdown2

app = Flask(__name__)
metrics = PrometheusMetrics(app)

metrics.info('app_info', 'Application info', version='1.0.3')

CONTENTFUL_SPACE_ID = os.environ['CONTENTFUL_SPACE_ID']
CONTENTFUL_ACEESS_TOKEN = os.environ['CONTENTFUL_ACEESS_TOKEN']

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

    return render_template('tools.html', ip=ip, content=content)

metrics.register_default(
    metrics.counter(
        'by_path_counter', 'Request count by request paths',
        labels={'path': lambda: request.path}
    )
)

if __name__ == '__main__':
    app.run()

