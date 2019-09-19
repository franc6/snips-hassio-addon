from base64 import b64decode
from datetime import datetime
import filecmp
import json
import os
from pathlib import Path
import re
import requests
from shutil import copyfile
import subprocess
import sys
from tempfile import NamedTemporaryFile
import zipfile
from cheroot.wsgi import Server as WSGIServer, PathInfoDispatcher
from flask import Flask, abort, render_template, request
import snipsConsole

fileNames = []
root = ''
assistant_zip = None
email = ''
password = ''

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
    return render_template('index.html', fileNames=fileNames, root=root, addon_version=addon_version, snips_version=snips_version, email=email, assistant_zip=assistant_zip)

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

@app.route('/assistant-list')
def assistant_list():
    snips = snipsConsole.SnipsConsole()
    if not snips.login(email, password):
        error("Could not login")
        abort(401)

    assistants = snips.get_assistant_list()
    snips.logout()
    if assistants is None:
        abort(404)
    return app.response_class(assistants, mimetype='text/plain', status=200)

@app.route('/download-assistant')
def download_assistant():
    assistant_id = request.args.get('AssistantID')
    snips = snipsConsole.SnipsConsole()
    if not snips.login(email, password):
        error("Could not login")
        abort(401)

    try:
        with NamedTemporaryFile() as temp_file:
            download_success = snips.download_assistant(assistant_id, temp_file)
            snips.logout()
            if not download_success:
                error("Failed to download assistant: {}".format(assistant_id))
                abort_code = 500
                abort(abort_code)
            if not zipfile.is_zipfile(temp_file.name):
                error("Didn't download a ZIP file!")
                abort_code = 404
                abort(abort_code)
            status = 202
            if not filecmp.cmp(assistant_zip, temp_file.name):
                status = 200
                try:
                    info("Files are not the same; will copy and extract")
                    copyfile(temp_file.name, assistant_zip)
                    extract_assistant()
                except Exception as e:
                    error("Caught exception copying temp file or installing assistant")
                    error("Exception: {}".format(e))
                    abort_code = 500
                    abort(abort_code)
            else:
                info("Files are the same!")
            return app.response_class(" ", mimetype='text/plain', status=status)
    except Exception as e:
        snips.logout()
        if abort_code is None:
            error("Caught exception downloading assistant")
            error("Exception: {}".format(e))
            abort_code = 500
        abort(abort_code)

    return app.response_class(' ', mimetype='text/plain', status=403)

@app.route('/save-config', methods=['POST'])
def save_config():
    file_name = request.headers.get('X-File-Name')
    if file_name and allowed_file(file_name):
        final_name = '/share/snips/' + file_name
        skill_config_name = '/var/lib/snips/skills/' + config_ini_re.sub('/config.ini', file_name)
        bytes_left = int(request.headers.get('Content-Length'))
        with NamedTemporaryFile() as temp_file:
            chunk_size = 4096
            while bytes_left > 0:
                chunk = request.stream.read(chunk_size)
                temp_file.write(chunk)
                bytes_left -= len(chunk)
            temp_file.flush()
            if not filecmp.cmp(final_name, temp_file.name):
                try:
                    copyfile(temp_file.name, final_name)
                    # Don't bother trying to copy the file or restart the
                    # skills server if the skill doesn't actually exist!  This
                    # can happen, e.g., if someone removed a skill from their
                    # assistant.  Response should be 202 in that case
                    status = 202
                    if os.path.exists(skill_config_name):
                        copyfile(temp_file.name, skill_config_name)
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
    extract_assistant()
    return app.response_class(" ", mimetype='text/plain')

def extract_assistant():
    subprocess.call(['/extract_assistant.sh'])

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

    with open('/data/options.json', 'r') as f:
        config = json.load(f)
        if 'email' in config['snips_console']:
            email = config['snips_console']['email']
        if 'password' in config['snips_console']:
            password = config['snips_console']['password']
        assistant_zip = config['assistant']

    dispatcher = PathInfoDispatcher({'/': app.wsgi_app, root: app.wsgi_app})
    server = WSGIServer((host, port), dispatcher)

    try:
        info("Starting server!")
        server.start()
    except Exception as e:
        error("caught exception: {}".format(e))
        server.stop()

