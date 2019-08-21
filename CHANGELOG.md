## 0.1.48 2019/08/20
- Added code to update the HA config with python scripts from Home Assistant snippets.  This includes updating the intent_script settings for the appropriate intents and python_script.  If the configuration is updated, a message will be logged to indicate that HA should be restarted.  Eventually, the addon should restart HA on its own.

## 0.1.47 2019/08/17
- Fixed bug where snips-watch is always run
- Added first-pass code for updating the assistant without restarting the container

## 0.1.46 2019/08/15
- Added Web UI (ingress) support

## 0.1.45 2019/08/13
- Added apparmor

## 0.1.32 2019/08/12
- Initial release.
