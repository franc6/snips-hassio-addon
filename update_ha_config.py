#!/usr/bin/env python3

from datetime import datetime
import filecmp
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

ha_app_dirs = sys.argv[1:]
need_restart = False

def log(color, level, message):
    msg = "[{time}] {level}: {color}{message}[0m".format(time=datetime.now().strftime("%H:%M:%S"), level=level, color=color, message=message)
    print(msg)

def log_error(message):
    log('[31m', "ERROR", "{}".format(message))

def log_info(message):
    log('[34m', "INFO", "{}".format(message))

def log_warning(message):
    log('[33m', "WARNING", "{}".format(message))

def add_intent_script(intent_script_yaml, name, file_name):
    log_info("Installing python_script: {}".format(file_name.name))
    copyfile(file_name, python_scripts_dir / file_name.name)
    service = "python_script." + file_name.stem
    if not 'intent_script' in intent_script_yaml:
        intent_script_yaml[name] = { "action": { 'service': service } }
    else:
        intent_script_yaml['intent_script'][name] = { "action": { 'service': service } }
    return intent_script_yaml

def add_intent_scripts(intent_script_yaml):
    for app_dir in ha_app_dirs:
        log_info("processing dir: {}".format(skill_dir / app_dir))
        (username, suffix) = app_dir.lower().split('.')
        regex_pattern = r"^action_{username}_(.+)_{username}_{suffix}.py$".format(username=username, suffix=suffix)
        regex = re.compile(regex_pattern)
        file_list = Path(skill_dir / app_dir).glob('action_*.py')
        for app_file in file_list:
            app = regex.sub(r'\1', str(app_file.name))
            intent_script_yaml = add_intent_script(intent_script_yaml, app, skill_dir / app_file)
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
            iscode = yaml.load("""""")
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
