FROM snips AS addon

RUN set -x \
    && mkdir -p \
        /ingress/templates \
        /ingress/static \
        /EXTRA-LICENSES \
    && pip3 install \
        flask \
        requests \
        ruamel.yaml \
        cheroot

COPY --from=mimic /usr/local/bin/* /usr/local/bin/

COPY ingress/*.py /ingress/
COPY ingress/templates/* /ingress/templates/
COPY ingress/static/* /ingress/static/

COPY funcs.sh \
    extract_assistant.sh \
    manage_tts_cache.sh \
    restart_snips_skill_server.sh \
    run.sh \
    setup.sh \
    start_service.sh \
    start_snips_watch.sh \
    stop_snips_watch.sh \
    update_ha_config.py \
    wait-for-it.sh \
    /
COPY LICENSE EXTRA-LICENSES/* /EXTRA-LICENSES/
COPY tts-unparsed.sh /tts/

RUN set -x \
    && rm -rf /etc/supervisor \
    && mkdir /etc/supervisor \
    && chmod 755 \
        /extract_assistant.sh \
        /manage_tts_cache.sh \
        /restart_snips_skill_server.sh \
        /run.sh \
        /start_service.sh \
        /start_snips_watch.sh \
        /stop_snips_watch.sh \
        /update_ha_config.py \
        /wait-for-it.sh \
        /ingress/ \
        /ingress/static/ \
        /ingress/templates/ \
        /ingress/control.py \
        /etc/supervisor/ \
        /tts/ \
    && chmod 644 \
        /funcs.sh \
        /ingress/static/* \
        /ingress/templates/* \
        /setup.sh \
        /tts/tts-unparsed.sh

ENTRYPOINT [ "/run.sh" ]
