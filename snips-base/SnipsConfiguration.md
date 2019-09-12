# Configuring snips
Besides the add-on's configuration, there are other items that might need
configured for your snips installation to work.

## Providing your own snips.toml
If you create a snips.toml file in /share/snips or /share, that file will be
used, and the tts and google_asr_credentials settings from the add-on
configuration will be ignored.  You can use the tts settings, you'll need to
use the following settings in your snips.toml file:

```ini
[snips-tts]
provider = "customtts"
customtts = { cmmand = [ "/tts/tts.sh", "%%OUTPUT_FILE%%", "%%TEXT%%" ] }
```

Since the google_asr_credentials setting is a single string, you can easily
add it directly to your custom snips.toml file.

## Configuring Skills
Many snips skills must be configured. Configuration is typically handled
through a file named config.ini in the skill's directory.  Since this
directory is not visible, this add-on will copy configuration files from
/share/snips/.  Name the configuration file "\<skillname>-config.ini" where
"\<skillname>" is the name of the skill.  Skills which require configuration
and appear on the snips app store will list the required configuration
items.  Many skills provide a default config.ini file, which will be copied
to /share/snips/ for you to edit later.

You can view and edit the configuration files in /share/snips through the
Web UI.  When you save the cofiguration file, the snips-skill-server
will be restarted for you.

If you edit the configuration files directly (i.e., not through the Web UI),
you must restart the add-on, or click "Update Assistant" in the Web UI for
the changes to take effect.

![Web UI Logs Screenshot](/screenshots/snips-base-webui-config.png?raw=true)

## Home Assistant Snippets
If your assistant uses Home Assistant Snippets, they will be installed to
/config/python_script and /config/configuration.yaml will be updated to
enable the intent_script, python_script, and snips components.  If you had
alread configured those components, the snips and python_script components
will remain untouched.  If intent_script was set to an included file, that
included file will be used.  If intent_script was not configured, it will be
configured to use an included file, named intent_script.yaml.  In either
event, the existing intent_script configuration will be updated to reference
the intents for your assistant that use snippets.

If your configuration files are modified, your original file will be copied
to the same name ending with a `~`.  E.g., if configuration.yaml is
modified, the original file will be copied to a new file named
"configuration.yaml`~`".  Additionally, the file indents will be normalized
to 2 space indents, if they were not already.  All comments in the file will
be preserved.

You might need to restart Home Assistant if the configuration was updated.
The log will include a message to indicate this.  If no changes are
necessary to configure Home Assistant for use with your assistant, your
files will not be modified.  If you set the configuration option,
"restart_home_assistant" to true, then the add-on will attempt to restart
Home Assistant for you, when necessary.  If it fails, you'll see a message
in the logs indicating you need to restart Home Assistant.  When you start
the add-on, the message indicating if you need to restart Home Assistant
will appear in the Log at the bottom of the add-on's page.  When you use the
Web UI's "Update Assistant" button, the message will appear in
"ingress.log".

The Home Assistant configuration will be checked (and potentially modified)
when you start the add-on and when you update your assistant.

