# Web UI

## Server Controls
The Web UI lets you update the assistant without restarting the whole
add-on.  Simply copy your new assistant's .ZIP file over the old one (see
configuration), and click "Update Assistant".  Updating will take a few
minutes.  You'll receive a message when it has finished.  Please do not
navigate from the WebUI while it is updating.

You can start and stop snips-watch on demand from the Web UI, too.  This can
help with trouble-shooting problems with snips.  Please note that this
feature doesn't affect your configuration.  If snips-watch is disabled in
the configuration, starting it through the Web UI will not make it run when
you restart the add-on.  It will also stop running (or start running) when
you update your assistant, based on the configuration.

![Web UI Logs Screenshot](/snips-base/screenshots/snips-base-webui.png?raw=true)

## Logs
You can view the log files for the Web UI, internal mosquitto, and snips
programs.  You can choose how frequently the interface updates the logs.  If
you have enabled snips-watch (or started it from the Web UI), its output
will be the first log file listed.

![Web UI Logs Screenshot](/snips-base/screenshots/snips-base-webui-logs.png?raw=true)

## Skills Configuration
You can configure your skills from the Web UI.  Any config.ini files which
are in /share/snips will be listed in this section.  When you save a
configuration file, the snips-skill-server will be restarted, so the changes
will take effect soon.

![Web UI Logs Screenshot](/snips-base/screenshots/snips-base-webui-config.png?raw=true)
