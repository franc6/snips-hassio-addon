# snips-hassio-addon
A snips addon for hassio.  Based on https://github.com/dYalib/snips-docker.git
and the official snips addon, with some improvements of my own.  The official
addon is designed to work only with assistants whose skills do everything
through Home Assistant.  Unfortunately, most of the skills available for snips
assistants don't work that way.  Some of those skills do things that Home
Assistant can't (yet), while others don't even make sense to work through Home
Assistant.  This addon is intended to let you use an assistant withs skills
that run only on snips as well as skills that work through Home Assistant.

## Features
- Works only with satellites
- Configuration of snips skills
- Installs home assistant skills (incomplete)
- Exposes log files (via /share/snips/logs)
- Generates snips.toml based on configuration, or allows you to use your own

## Configuration
| Option | Values | Explanation |
|--------|--------|-------------|
|analytics|true or false|If true, snips-analytics will be started.|
|assistant|file name|The name of your snips assistant, in a zip file.  This should be a path relative to /share/snips or /share.|
|cafile|file name|If your hass.io MQTT server uses TLS, specify a file containing the CA certificate for it here.  This should be a path relative to /share/snips or /share.  If you are using the MQTT addon, you don't need this.|
|google_asr_credentials|string|If you want to use Google's ASR, specify your API key here.|
|language|en, fr, or de|Indicate which langue you're using, en for English, fr for French, or de for German.|
|country_code|ISO 3166 country code|Your two-letter country code, e.g. US for the United States of America.|
|custom_tts.active|true or false|If true, a custom text-to-speech setting will be used for snips.|
|custom_tts.platform|mimic or pico2wave|Which custom TTS to use. For now, only mimic and pico2wave are supported.  Support for SuperSnipsTTS is planned.|
|custom_tts.voice|string|A string that represents which voice to use.  For mimic, this should be the full path of a flitevox file.  For pico2wave this specifies the voice and country, such as "en-US"|
|snips_watch|true or false|If true, snips-watch will be started.  Use the Web UI to view its output.|

Please note that flitevox files for mimic are not included in the image, so if
you want to use mimic, you'll need to copy the flitevox file to /share and list
the full path to it in the custom_tts.voice option.

### Providing your own snips.toml
If you create a snips.toml file in /share/snips or /share, that file will be
used, and the custom_tts and google_asr_credentials settings will be ignored.

## Configuring Skills
Many snips skills must be configured. Configuration is typically handled
through a file named config.ini in the skill's directory.  Since this directory
is not visible, this addon will copy configuration files from /share/snips/.
Name the configuration file "<skillname>-config.ini" where "<skillname>" is the
name of the skill.  Skills which require configuration and appear on the snips
app store will list the required configuration items.

You must restart the addon after changing <skillname>-config.ini for the
changes to take affect.

## Home Assistant Snippets
If your assistant uses Home Assistant Snippets, they will be installed to
/config/python_script and /config/configuration.yaml will be updated to enable
the intent_script, python_script, and snips components.  If you had alread
configured those components, the snips and python_script components will remain
untouched.  If intent_script was set to an included file, that included file
will be used.  If intent_script was not configured, it will be configured to
use an included file, named intent_script.yaml.  In either event, the existing
intent_script configuration will be updated to reference the intents for your
assistant that use snippets.

If your configuration files are modified, your original file will be copied to
the same name ending with a `~`.  E.g., if configuration.yaml is modified, the
original file will be copied to a new file named "configuration.yaml`~`".
Additionally, the file indents will be normalized to 2 space indents, if they
were not already.  All comments in the file will be preserved.

You will need to restart HA if the configuration was updated.  The log will
include a message to indicate this; you don't need to check the files yourself.
If no changes are necessary to configure HA for use with your assistant, your
files will not be modified.

The HA configuration will be checked (and potentially modified) when you start
the addon and when you update your assistant.

## Satellite Configuration
In /etc/snips.toml:
```toml
[snips-common]
mqtt = "host:9883"
[snips-audio-server]
bind = "satellite@mqtt"
```
"host" is the hostname of the computer running this addon.  You can find the
hostname by looking at the "System" tab of the Hass.io page.  "satellite" is a
unique name for the satellite.  If you have multiple satellites, the name of
its location is a good choice.  No other configuration changes are necessary
for the satellite.  Be sure to only run snips-hotword and snips-audio-server on
the satellite.

## Logs
The Log shown at the bottom of the addon page shows the start-up info for the
addon.  Snips isn't ready for use until you see the message "snips-skill-server
entered RUNNING state".  How long this takes will depend on how many skills are
in your assistant, the speed of your internet connection, and the speed of your
host computer.

Log files for the programs running in the addon are stored in
/share/snips/logs.  This directory is created if it doesn't exist.
 
## Web UI
The Web UI lets you update the assistant without restarting the whole addon.
Simply copy your new assistant's .ZIP file over the old one (see
configuration), and click "Update Assistant".  Updating will take a few
minutes.  You'll receive a message when it has finished.  Please do not
navigate from the WebUI while it is updating.

You can also view the log files for the internal mosquitto and snips
programs.  You can choose how frequently the interface updates the logs.  If
you have enabled snips-watch, you can view its output from here, too.

## Accessing /share
The best ways to access /share are through the samba and ssh addons.  Check their documentation for more information.

## TODO
The following list is in no particular order...

- Restart HA instead of telling the user to do it, when the HA config is updated.
- Support the SuperSnipsTTS script.
- Support on-device audio, but only if it exists.
- Add support for configuring skills in the assistant -- through the web ui or through config flows??
- Automatically download assistant ZIP file (requires config updates, too)

[![Buy me some pizza](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/qpunYPZx5)
