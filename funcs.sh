function check_for_file() {
    bashio::log.info "Checking for /share/snips/$1"
    if [ -f "/share/snips/$1" ]; then
	echo "/share/snips/$1"
	return 0
    fi
    bashio::log.info "Checking for /share/$1"
    if [ -f "/share/$1" ]; then
	echo "/share/$1"
	return 0
    fi
    echo
}

function extract_assistant() {
    assistant_file="$1"
    ha_app_dirs=()
    assistant=$(check_for_file "${assistant_file}")
    if [ -n "${assistant}" ]; then
	bashio::log.info "Installing snips assistant from "${assistant}""
	rm -rf /usr/share/snips/assistant
	unzip -qq -d /usr/share/snips "${assistant}"
    else
	bashio::log.error "Could not find the snips assistant!"
	return 1
    fi

    bashio::log.info "Clearing existing skills"
    #start with a clear skill directory
    rm -rf /var/lib/snips/skills/*

    #deploy apps (skills). See: https://snips.gitbook.io/documentation/console/deploying-your-skills
    bashio::log.info "Rendering snips templates"
    snips-template render

    #goto skill directory
    cd /var/lib/snips/skills

    bashio::log.info "Cloning git-based skills"
    #download required skills from git
    for url in $(awk '$1=="url:" {print $2}' /usr/share/snips/assistant/Snipsfile.yaml); do
	    git clone -q $url
    done

    #be sure we are in the skill directory
    cd /var/lib/snips/skills

    # run setup.sh for each skill, and link any config.ini file for it
    # since we can't interact with the user, we have to do something else to get
    # config.ini files in place!
    for dir in * ; do
	if [ -d "$dir" ]; then
	    cd "$dir" 
	    skillname="$dir"
	    if [ -f setup.sh ]; then
		bashio::log.info "Running setup.sh for ${skillname}"
		#run the scrips always with bash
		bash ./setup.sh >/dev/null 2>/dev/null
	    fi
	    skillconfigfile=$(check_for_file ${skillname}-config.ini)
	    if [ -n "${skillconfigfile}" ] ; then
		bashio::log.info "Copying ${skillconfigfile} to config.ini for ${skillname}"
		rm -f config.ini
		cp "${skillconfigfile}" "config.ini"
	    fi
	    if [ -f "spec.json" ]; then
		spec_json_name="$(jq --raw-output '.name' spec.json)"
		spec_json_language="$(jq --raw-output '.language' spec.json)"
		if [ "X${spec_json_name}" = "Xhomeassistant" ]; then
		    if [ "X${spec_json_language}" = "XPYTHON" ]; then
			bashio::log.info "${skillname} uses python_script in HA"
			ha_app_dirs+=(${skillname})
		    fi
		fi
	    fi
	    cd /var/lib/snips/skills
	fi
    done
    bashio::log.info "Finished deploying skills"

    if [ ${#ha_app_dirs[@]} -ne 0 ]; then
	cd /var/lib/snips/skills
	bashio::log.info "Updating HA configuration"
	/update_ha_config.py ${ha_app_dirs[@]}
	need_restart=$?

	if [ ${need_restart} -ne 0 ]; then
	    bashio::log.warning "HA configuration was modified.  You need to restart it!"
	fi
    fi

    # Go back to /!
    cd /

    return 0
}

SUPERVISORD_CONF="/etc/supervisor/supervisord.conf"
function kill_snips_skills() {
    supervisorctl -c ${SUPERVISORD_CONF} restart snips-group:
}
