from flask import Flask, render_template, redirect, url_for, request, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/me')
def me():
    return render_template('me.html', request=request)

@app.route('/tools')
def tools():
    return render_template('tools.html', request=request)

if __name__ == '__main__':
    app.run()

