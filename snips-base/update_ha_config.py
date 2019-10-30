#!/usr/bin/env python3

from datetime import datetime
import filecmp
import json
import os
from pathlib import Path
import re
from shutil import copyfile
import sys
from tempfile import NamedTemporaryFile
from ruamel.yaml import YAML
from ruamel.yaml.comments import (Tag, TaggedScalar)

config_dir = Path('/config')
python_scripts_dir = config_dir / 'python_scripts'
skill_dir = Path('/var/lib/snips/skills')
assistant_dir = Path('/usr/share/snips/assistant')

ha_app_dirs = sys.argv[1:]
need_restart = False
fix_name_re = re.compile(r'_+')

def log(color, level, message):
    msg = "[{time}] {level}: {color}{message}[0m".format(time=datetime.now().strftime("%H:%M:%S"), level=level, color=color, message=message)
    print(msg)

def log_error(message):
    log('[31m', "ERROR", "{}".format(message))

def log_info(message):
    log('[34m', "INFO", "{}".format(message))

def log_warning(message):
    log('[33m', "WARNING", "{}".format(message))

def add_intent_script(intent_script_yaml, intent, file_name, slots):
    log_info("Installing python_script: {}".format(file_name.name))
    # HA doesn't like multiple underscores in a row, so trim them to just one --
    # both for the real file name and in the service!
    copyfile(file_name, python_scripts_dir / fix_name_re.sub(r'_', file_name.name))
    service = "python_script." + fix_name_re.sub(r'_', file_name.stem)
    action = { "action": { 'service': service } }
    data_template = { }
    for slot in slots:
        data_template[slot] = "{{{{ {} }}}}".format(slot)
        data_template["{}_raw".format(slot)] = "{{{{ {}_raw }}}}".format(slot)
    data_template['confidenceScore'] = "{{ confidenceScore }}"
    data_template['siteId'] = "{{ site_id }}"
    data_template['sessionId'] = "{{ session_id }}"
    action['action']['data_template'] = data_template
    if not 'intent_script' in intent_script_yaml:
        intent_script_yaml[intent] = action
    else:
        intent_script_yaml['intent_script'][intent] = action
    return intent_script_yaml

def add_intent_scripts(intent_script_yaml):
    with open(assistant_dir / 'assistant.json') as f:
        assistant = json.load(f)
    for app_dir in ha_app_dirs:
        log_info("processing HA snippets for: {}".format(app_dir))
        (username, suffix) = app_dir.lower().split('.')
        suffix = suffix.replace('-', '_')
        file_list = Path(assistant_dir / 'snippets' / app_dir / 'homeassistant' / username).glob('*.snippet')
        for app_file in file_list:
            log_info("processing: {}".format(app_file))
            slots = []
            app = app_file.stem
            for intent in assistant['intents']:
                if intent['id'] == "{username}:{intent}".format(username=username, intent=app):
                    log_info("Found intent: {}".format(intent['id']))
                    for slot in intent['slots']:
                        slots.append(slot['name'])
                        log_info("Found slot: {}".format(slot['name']))
            py_file = "action_{username}_{intent}_{username}_{suffix}.py".format(username=username, intent=app.lower(), suffix=suffix)
            intent_script_yaml = add_intent_script(intent_script_yaml, app, skill_dir / app_dir / py_file, slots)
    return intent_script_yaml

def save_yaml(destination, yaml_code):
    restart = False
    tmp_output = NamedTemporaryFile(mode='w+t', delete=False)
    yaml.dump(yaml_code, tmp_output)
    tmp_output.close()

    if not filecmp.cmp(destination, tmp_output.name):
        restart = True
        try:
            copyfile(destination, Path(str(destination) + "~"))
            try:
                copyfile(tmp_output.name, destination)
            except:
                log_warning("Error copying {} to {}: {}".format(tmp_output.name, destination, sys.exc_info[0]))
        except:
            log_warning("Error making backup of {}: {}".format(destination, sys.exc_info[0]))
    os.unlink(tmp_output.name)
    return restart


if not python_scripts_dir.is_dir():
    if python_scripts_dir.exists():
        log_error("{} exists and is not a directory!  Please remove it and try again.".format(python_scripts_dir))
        sys.exit(0)
    else:
        python_scripts_dir.mkdir(mode=0o755)

yaml = YAML()
configuration_path = config_dir / 'configuration.yaml'
code = yaml.load(configuration_path)

if not 'python_script' in code:
    code['python_script'] = None
    code.yaml_set_comment_before_after_key('python_script', before='\nRequired for snips')

if not 'snips' in code:
    code['snips'] = None
    code.yaml_set_comment_before_after_key('snips', before='\nRequired for snips')

if not 'intent_script' in code:
    code['intent_script'] = TaggedScalar()
    code['intent_script'].yaml_set_tag('!include')
    code['intent_script'].value = 'intent_script.yaml'
    code.yaml_set_comment_before_after_key('intent_script', before='\nRequired for snips')

if isinstance(code['intent_script'], TaggedScalar):
    if code['intent_script'].tag.value != '!include':
        log_warning("Don't know what to do with tag: {}".format(code['intent_script'].tag))
    else:
        if code['intent_script'].value.startswith('/'):
            intent_script_path = Path(code['intent_script'].value)
        else:
            intent_script_path = config_dir / code['intent_script'].value
        if intent_script_path.exists():
            iscode = yaml.load(intent_script_path)
        else:
            iscode = YAML()
        iscode = add_intent_scripts(iscode)
        need_restart = save_yaml(intent_script_path, iscode)

else:
    code = add_intent_scripts(code)

# Be sure not to set need_restart to False just because this call to save_yaml
# returns False!
if save_yaml(configuration_path, code):
    need_restart = True

if need_restart:
    sys.exit(1)

sys.exit(0)
