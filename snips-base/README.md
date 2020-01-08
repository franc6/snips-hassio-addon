# IMPORTANT NOTICE!

All licenses for this software are revoked as of Jan 31, 2020.  You are NOT
allowed to use this software after Jan 31, 2020.  Modifications and
distributions of this app are expressly forbidden.

Sonos purchased Snips in 2019, and announced that the Snips Console will be
closed as of January 31, 2020.  By closing the Snips Console, Sonos has
indicated a desire to move Snips to a closed system.  I don't have any problem
with that.  However, having worked for a number of software and other
companies, I fear that Sonos' management was under the mistaken belief that all
of the software available for the Snips platform was part of their purchase.
This is not the case, as most of the software for the platform was developed by
other entities.  By revoking the license, I hope to make it clear to Sonos that
any copying, modification, use, or distribution of my software by Sonos is a
violation of copyright law.  If I learn that Sonos is distributing software
that is substantially similar, I will take all necessary measures to stop all
distribution unless and until it is proven that Sonos has not undertaken any
illegal activity in that distribution.

# snips-hassio-add-on
A snips add-on for hassio.  This project was originally inspired by
[https://github.com/dYalib/snips-docker.git](https://github.com/dYalib/snips-docker.git)
and the official snips add-on.  This project doesn't have much in common
with either of those projects, and does several things very differently.
The official add-on is designed to work only with assistants whose skills do
everything through Home Assistant.  Unfortunately, most of the skills
available for snips assistants don't work that way.  Some of those skills do
things that Home Assistant can't (yet), while others don't even make sense
to work through Home Assistant.  This add-on is intended to let you use an
assistant withs skills that run only on snips as well as skills that work
through Home Assistant.

## Alpha Quality Software
Currently, this is "alpha quality" software.  This means that some features
may be untested, and there may be breaking changes between updates.
That said, most of the features are of "beta quality", and have been tested
extensively.  The features which need the most testing are:

- Google Cloud Text-to-Speech
- Amazon Polly
- Snips assistants which use javascript-based skills
- More variety of skills and Home Assistant snippets

## Features
- Works only with satellites
- Downloads and installs your assistant from the Snips Console (via Web UI, if configured)
- Configuration of snips skills (via Web UI or your favorite text editor)
- Installs Home Assistant skills (and optionally restarts Home Assistant if necessary)
- Exposes log files (via WebUI and /share/snips/logs)
- Generates snips.toml based on configuration, or allows you to use your own
- Allows the use of higher quality voices, both locally and through the internet

## Configuration
See ![Add-on Configuration](/snips-base/Add-onConfiguration.md)

## Configuring Skills
See ![Snips Configuration](/snips-base/SnipsConfiguration.md)

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
See ![Web UI](/snips-base/WebUI.md)

## Accessing /share
The best ways to access /share are through the samba and ssh add-ons.  Check
their documentation for more information.

## TODO
The following list is in no particular order, but represent the features I
think are still needed before a 1.0 release (that doesn't mean these will
make it).

- Automatically download assistant ZIP file from the snips console or a git repository
- Support on-device audio, but only if it exists -- maybe a satellite add-on?
- Translation of UI and documentation
- Spoken notification/alert when snips is all up and running?

