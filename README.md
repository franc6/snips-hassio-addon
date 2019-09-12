# snips-hassio-add-on
A snips add-on for hassio.  This project was originally inspired by
https://github.com/dYalib/snips-docker.git and the official snips add-on.
This project doesn't have much in common with either of those projects, and
does several things very differently.  The official add-on is designed to
work only with assistants whose skills do everything through Home Assistant.
Unfortunately, most of the skills available for snips assistants don't work
that way.  Some of those skills do things that Home Assistant can't (yet),
while others don't even make sense to work through Home Assistant.  This
add-on is intended to let you use an assistant withs skills that run only on
snips as well as skills that work through Home Assistant.

## Features
- Works only with satellites
- Configuration of snips skills (via Web UI or your favorite text editor)
- Installs Home Assistant skills (and optionally restarts Home Assistant if necessary)
- Exposes log files (via WebUI and /share/snips/logs)
- Generates snips.toml based on configuration, or allows you to use your own
- Allows the use of higher quality voices, both locally and through the internet

## Configuration
See ![Add-on Configuration](/Add-onConfiguration.md)

## Configuring Skills
See ![Snips Configuration](/SnipsConfiguration.md)

## Satellite Configuration
In /etc/snips.toml:
```toml
[snips-common]
mqtt = "host:9883"
[snips-audio-server]
bind = "satellite@mqtt"
```
"host" is the hostname of the computer running this add-on.  You can find
the hostname by looking at the "System" tab of the Hass.io page.
"satellite" is a unique name for the satellite.  If you have multiple
satellites, the name of its location is a good choice.  No other
configuration changes are necessary for the satellite.  Be sure to only run
snips-hotword and snips-audio-server on the satellite.

## Logs
The Log shown at the bottom of the add-on page shows the start-up info for
the add-on.

Log files for the programs running in the add-on are stored in
/share/snips/logs.  This directory is created if it doesn't exist.
 
## Web UI
See ![Web UI Configuration](/WebUIConfiguration.md)

## Accessing /share
The best ways to access /share are through the samba and ssh add-ons.  Check
their documentation for more information.

## TODO
The following list is in no particular order, but represent the features I
think are still needed before a 1.0 release.

- Support on-device audio, but only if it exists
- Automatically download assistant ZIP file from the snips console or a git repository

[![Buy me some pizza](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/qpunYPZx5)
