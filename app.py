from flask import Flask, render_template, redirect, url_for, request, jsonify
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

metrics.info('app_info', 'Application info', version='1.0.3')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/me')
def me():
    return render_template('me.html', request=request)

@app.route('/tools')
def tools():
    return render_template('tools.html', request=request)

metrics.register_default(
    metrics.counter(
        'by_path_counter', 'Request count by request paths',
        labels={'path': lambda: request.path}
    )
)

if __name__ == '__main__':
    app.run()

