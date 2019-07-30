# snips-hassio-addon
A snips addon for hassio.  Based on https://github.com/dYalib/snips-docker.git
and the official snips addon, with some improvements of my own additions.

## Features
- Works only with satellites
- Configuration of snips skills
- Installs home assistant skills (incomplete)
- Exposes log files (via /share/snips/logs)
- Generates snips.toml based on configuration, or allows you to run your own

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

If you create a snips.toml file in /share/snips or /share, that file will be
used, and the custom_tts and google_asr_credentials settings will be ignored.
Please note that flitevox files are not included in the image, so if you want
to use mimic, you'll need to copy the flitevox file to /share and list the full
path to it.

## Configuring Skills
Many snips skills must be configured. Configuration is typically handled
through a file named config.ini in the skill's directory.  Since this directory
is not visible, this addon will copy configuration files from /share/snips/.
Name the configuration file "<skillname>-config.ini" where "<skillname>" is the
name of the skill.  Skills which require configuration and appear on the snips
app store will list the required configuration items.

## Satellite Configuration
In /etc/snips.toml:
```toml
[snips-common]
mqtt = "host:9883"
[snips-audio-server]
bind = "satellite@mqtt"
```
"host" is the hostname of the computer running this addon.  This is not the
name of the container, it's the name of the host computer.  "satellite" is a
unique name for the satellite.  If you have multiple satellites, the name of
its location is a good choice.  No other configuration changes are necessary
for the satellite.  Be sure to only run snips-hotword and snips-audio-server on
the satellite.

## Logs
Log files are stored in /share/snips/logs.  This directory is created if it
doesn't exist.
 
## Accessing /share
The best way to access /share is through the samba addon.  Simply install and
start the addon, and this directory will be made available as a share named
"share".

## TODO
- Determine how to update configuration.yaml so that intents from snips that need to run homeassistant scripts will work without user interaction.  For now, the home assistant scripts are installed in /config/python_scripts, but they won't actually run until configuration.yaml is updated.
- Support the SuperSnipsTTS script
- Support on-device audio, but only if it exists
- Add ingress support; should be able to view the log files, and run snips-watch
- Add AppArmor support; this will probably have to wait on the snips.ai team, because I'm too lazy to figure out what all the various components of snips need access to.



