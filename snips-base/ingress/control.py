from datetime import datetime
import filecmp
import os
from pathlib import Path
import re
from shutil import copyfile
import subprocess
import sys
from tempfile import NamedTemporaryFile
from cheroot.wsgi import Server as WSGIServer, PathInfoDispatcher
from flask import Flask, abort, render_template, request

fileNames = []
root = ''

config_ini_re = re.compile(r'-config.ini$')

app = Flask(__name__)

def logme(level, message):
    time = datetime.now()
    with open('/share/snips/logs/ingress.log', 'a') as log_file:
        print("[{time}] {level}: {message}".format(time=time, level=level, message=message), file=log_file)

def info(message):
    logme('INFO', message)

def warning(message):
    logme('WARNING', message)

def error(message):
    logme('ERROR', message)

def allowed_file(file_name):
    return file_name.endswith('-config.ini')

@app.before_request
def limit_remote():
    if request.remote_addr != '172.30.32.2':
        abort(403)

@app.route('/')
def index():
    return render_template('index.html', fileNames = fileNames, root = root, addon_version = addon_version, snips_version = snips_version)

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

@app.route('/config_file_list')
def config_file_list():
    file_list = Path('/share/snips/').glob('*-config.ini')
    response = '<ul>'
    for file_name in file_list:
        response += '<li class="configFile" onclick="showConfig(this)">{name}</li>'.format(name=file_name.name)
    response += '</ul>'
    return app.response_class(response, mimetype='text/html')

@app.route('/config')
def config_file():
    ini=request.args.get('ini')
    if not ini.endswith('-config.ini'):
        abort(403)
    return app.response_class(generate('/share/snips/', ini), mimetype='text/plain')

@app.route('/save-config', methods=['POST'])
def save_config():
    file_name = request.headers.get('X-File-Name')
    if file_name and allowed_file(file_name):
        final_name = '/share/snips/' + file_name
        skill_config_name = '/var/lib/snips/skills/' + config_ini_re.sub('/config.ini', file_name)
        bytes_left = int(request.headers.get('Content-Length'))
        with NamedTemporaryFile() as temp_file:
            temp_name = temp_file.name
            chunk_size = 4096
            while bytes_left > 0:
                chunk = request.stream.read(chunk_size)
                temp_file.write(chunk)
                bytes_left -= len(chunk)
            temp_file.flush()
            if not filecmp.cmp(final_name, temp_name):
                try:
                    copyfile(temp_name, final_name)
                    # Don't bother trying to copy the file or restart the
                    # skills server if the skill doesn't actually exist!  This
                    # can happen, e.g., if someone removed a skill from their
                    # assistant.  Response should be 202 in that case
                    status = 202
                    info("Checking if {} exists".format(skill_config_name))
                    if os.path.exists(skill_config_name):
                        copyfile(temp_name, skill_config_name)
                        subprocess.call(['/restart_snips_skill_server.sh'])
                        status = 200
                    return app.response_class(' ', mimetype='text/plain', status=status)
                except Exception as e:
                    error("Caught exception copying temp file or restarting snips-skill-server")
                    error("Exception: {}".format(e))
                    abort(500)
            return app.response_class(' ', mimetype='text/plain', status=208)
    abort(403)

@app.route('/stream')
def stream():
    log=request.args.get('log')
    if log not in fileNames:
        abort(403)
    return app.response_class(generate('/share/snips/logs/', log), mimetype='text/plain')

@app.route('/update-assistant')
def update_assistant():
    subprocess.call(['/extract_assistant.sh'])
    return app.response_class(" ", mimetype='text/plain')

def generate(directory, log):
    lines = []
    try:
        with open(directory+log, "r") as f:
            line = f.readline()
            while line:
                lines.append(line)
                lines = lines[-100:]
                line = f.readline()
            return lines
    except Exception as e:
        error("Couldn't open " + log)
        error("Exception: {}".format(e))
    return ""


# There should really be some more error handling here...
if __name__ == '__main__':
    host = sys.argv[1]
    port = int(sys.argv[2])
    root = sys.argv[3]
    addon_version = sys.argv[4]
    snips_version = sys.argv[5]
    fileNames = sys.argv[6:]
    if 'snips-watch.log' in fileNames:
        fileNames.remove('snips-watch.log')
        fileNames.insert(0, 'snips-watch.log')

    dispatcher = PathInfoDispatcher({'/': app.wsgi_app, root: app.wsgi_app})
    server = WSGIServer((host, port), dispatcher)

    try:
        info("Starting server!")
        server.start()
    except Exception as e:
        error("caught exception: {}".format(e))
        server.stop()

