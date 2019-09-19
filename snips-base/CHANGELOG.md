## 0.5.0 2019/09/19
- Added support for downloading and installing snips assistants directly from the Snips Console
- Improved handling of missing assistant ZIP file -- if it's missing and you have configured Snips Console login information, it'll continue startup, and let you use the Web UI to download and install an assistant
- Improved temp file handling in Web UI
- Added ability to configure Italian and Japanese as your language
- Added defaults for language and country if not configured
- Breaking changes to make add-on configuration a little more logical
- Minor UI tweaks

## 0.4.1 2019/09/12
- Fixed bug in apparmor.txt that prevented the add-on from starting

## 0.4.0 2019/09/12
- Revamped text-to-speech settings so that online text-to-speech services can be used
- Split README.md into multiple files

## 0.3.0 2019/09/08
- Added the ability to modify skills configuration files from the Web UI
- Reworked startup to be more efficient
- Disabled persistence in mosquitto, this leads to much faster start times

## 0.2.0 2019/09/05
- Added ability to start and stop snips-watch on the fly
- Added an option to restart HA if it needs to be restarted

## 0.1.49 2019/08/28
- Added confidenceScore, sessionId, siteId, and raw slot values to intents configured for Home Assistant snippets
- Fixed issue #3
- Fixed issue #4
- Reduced disk usage of log files
- Colorized log output

## 0.1.48 2019/08/21
- Added code to update the HA config with python scripts from Home Assistant snippets.  This includes updating the intent_script settings for the appropriate intents and python_script.  If the configuration is updated, a message will be logged to indicate that HA should be restarted.  Eventually, the addon should restart HA on its own.
- Simplified apparmor.txt to make it easier to maintain and tighten down permissions.

## 0.1.47 2019/08/17
- Fixed bug where snips-watch is always run
- Added first-pass code for updating the assistant without restarting the container

## 0.1.46 2019/08/15
- Added Web UI (ingress) support

## 0.1.45 2019/08/13
- Added apparmor

## 0.1.32 2019/08/12
- Initial release.
