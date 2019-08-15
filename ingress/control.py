import sys
from time import sleep
from flask import Flask, abort, render_template, request

fileNames = []
root = ''

app = Flask(__name__)

@app.before_request
def limit_remote():
    if request.remote_addr != '172.30.32.2':
        abort(403)

@app.route('/')
def index():
    return render_template('index.html', fileNames = fileNames, root = root)

@app.route('/stream')
def stream():
    log=request.args.get('log')
    def generate(log):
        lines = []
        try:
            with open('/share/snips/logs/'+log, "r") as f:
                line = f.readline()
                while line:
                    lines.append(line)
                    lines = lines[-100:]
                    line = f.readline()
                return lines
        except:
            print("Couldn't open " + log)
        return ""
    return app.response_class(generate(log), mimetype='text/plain')


class PrefixMiddleware(object):
    def __init__(self, app, prefix=''):
        self.app = app
        self.prefix = prefix

    def __call__(self, environ, start_response):
        if environ['PATH_INFO'].startswith(self.prefix):
            environ['PATH_INFO'] = environ['PATH_INFO'][len(self.prefix):]
            environ['SCRIPT_NAME'] = self.prefix
        return self.app(environ, start_response)

# There should really be some error handling here...
if __name__ == '__main__':
    host = sys.argv[1]
    port = sys.argv[2]
    root = sys.argv[3]
    fileNames = sys.argv[4:]
    app.wsgi_app = PrefixMiddleware(app.wsgi_app, prefix=root)

    app.run(host=host, port=port)
