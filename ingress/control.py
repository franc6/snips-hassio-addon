import subprocess
import sys
from time import sleep
from cheroot.wsgi import Server as WSGIServer, PathInfoDispatcher
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

@app.route('/ansi_up.js')
def ansi_up():
    return render_template('ansi_up.js')

@app.route('/start_snips_watch')
def start_snips_watch():
    if 'snips-watch.log' not in fileNames:
        fileNames.insert(0, 'snips-watch.log')
        subprocess.call(['/start_snips_watch.sh'])

    return app.response_class(" ", mimetype='text/plain')

@app.route('/stop_snips_watch')
def stop_snips_watch():
    if 'snips-watch.log' in fileNames:
        fileNames.remove('snips-watch.log')
        subprocess.call(['/stop_snips_watch.sh'])

    return app.response_class(" ", mimetype='text/plain')

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

@app.route('/update-assistant')
def update_assistant():
    subprocess.call(['/extract_assistant.sh'])
    return app.response_class(" ", mimetype='text/plain')


# There should really be some more error handling here...
if __name__ == '__main__':
    host = sys.argv[1]
    port = int(sys.argv[2])
    root = sys.argv[3]
    fileNames = sys.argv[4:]
    if 'snips-watch.log' in fileNames:
        fileNames.remove('snips-watch.log')
        fileNames.insert(0, 'snips-watch.log')

    app.config['UPLOAD_FOLDER'] = '/tmp/'

    dispatcher = PathInfoDispatcher({'/': app.wsgi_app, root: app.wsgi_app})
    server = WSGIServer((host, port), dispatcher)

    try:
        server.start()
    except Exception as e:
        print("caught exception: {}".format(e))
        server.stop()

