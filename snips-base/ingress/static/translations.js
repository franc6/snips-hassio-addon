// All translations go here.  Copy the 'en' member of the dictionary passed to
// the Localization ctor.  The string ID is the key name, and its value is the
// actual string to display.  Only translate the strings to display.
// Translating the string ID will break things.
// Strings that are displayed via javascript have IDs that start with Upper
// case letters.  Strings that are for an HTML element have IDs that start with
// lower case letters.
function initTranslations()
{
    window.localization = new Localization({
        'en': {
            // Strings displayed via javascript
            'NLUTraining': 'NLU Training in progress...',
            'ASRTraining': 'ASR Training in progress...',
            'Downloading': 'Download in progress...',
            'AssistantNotChanged': 'The assistant appears to be the same!',
            'AssistantUpdateFailed': 'Failed to update the assistant!',
            'AddonContactFailed': 'Failed to contact the addo-on!',
            'ConfigSavedAndSkillServerRestarted': '{0} was saved, and the skill server restarted.',
            'ConfigSavedNotUsed': '{0} was saved, but doesn\'t seem to be used.',
            'ConfigUnchanged': '{0} was not changed.',
            'ConfigPermissionDenied': 'You do not have access to change {0}!',
            'ConfigServerErrorDuringSave': 'The server encountered an error saving {0}',
            'ConfigUnknownResponseCode': 'Unknown response code: {0} while saving {1}',
            'UpdatingAssistant': 'Updating the assistant...',
            'AssistantUpdateDone': 'Finished updating the assistant.',
            // Begin strings for HTML here
            'title': 'Snips.AI Base for Hass.io',
            'addonVersion': 'Add-on version:',
            'snipsVersion': 'Snips version:',
            'serverControlsTabButton': 'Server Controls',
            'downloadAssistantTitle': 'Download, Install, and Update Assistant',
            'emptyAssistantsList': 'If the drop-list is empty, please check the add-on\'s Config; the snips_console settings are empty or incorrect.',
            'snipsAssistantsLabel': 'Snips Assistants:',
            'refreshAssistantsListButton': 'Refresh Assistants List',
            'installAssistantButton': 'Install Assistant',
            'updateAssistantTitle': 'Update Assistant',
            'updateAssistantButton': 'Update Assistant',
            'snipsWatchTitle': 'Snips-watch',
            'snipsWatchPara1': 'You can start and stop snips-watch, even if you didn\'t configure it to be started. Note that starting it here will not change the configuration. If it is disabled in the configuration, the next time you restart this add-on, snips-watch will not be running.',
            'snipsWatchPara2': 'The snips-watch log is always the first log file, when snips-watch is running.',
            'startSnipsWatchButton': 'Start snips-watch',
            'stopSnipsWatchButton': 'Stop snips-watch',
            'logsTabButton': 'Logs',
            'licensesTabButton': 'Licenses',
            'updateIntervalLabel': 'Update interval:',
            'setButton': 'Set',
            'loadingLogData': 'Loading log data, please wait...',
            'skillConfigsTabButton': 'Skill Configs',
            'keyboardTypeLabel': 'Keyboard type:',
            'reloadButton': 'Reload',
            'saveButton': 'Save',
            'loadingFileList': 'Loading file list, please wait...',
            'selectFile': 'Please select a file to the left.',
        }
    }, 'en', false);
}
