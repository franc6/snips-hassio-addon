# Add-on Configuration
| Option | Values | Default |
|--------|--------|---------|
|[assistant](#assistant)|file name|assistant.zip|
|[cafile](#cafile)|file name|certfile.pem|
|[country_code](#country_code)|string|US|
|[google_asr_credentials](#google_asr_credentials)|string||
|[language](#language)|de, en, fr, it, ja|en|
|[restart_home_assistant](#restart_home_assistant)|true, false|false|
|[snips_console](#snips_console)|See [snips_console](#snips_console)||
|[snips_extras](#snips_extras)|See [snips_extras](#snips_extras)||
|[tts](#tts-options)||See [TTS Options](#tts-options).|

## assistant
The name of your snips assistant, in a .ZIP file.  This should be a path
relative to /share/snips.  Note that if you use the Web UI to install your
assistant, this file will be replaced by the assistant that you install through
the Web UI.

## cafile
If your hass.io MQTT server uses TLS, specify a file containing the CA
certificate for it here.  This should be a path relative to /share/snips.

**Note: If you are using the MQTT add-on, you don't need this.**

## country_code
The ISO 3166 two-letter country code for where you are.  If you do not set
this, a default country will be chosen for you, based on the language setting.
DE for German, US for English, FR for French, IT for Italian, and JP for
Japanese.

## google_asr_credentials
If you want to use Google's ASR, specify your API key here.

## language
The two-letter language code, in lower case.  You can only set de, en, fr, it,
or ja at this time.  If you do not set this, a language will be chosen for you,
perhaps not the one you would choose.

## restart_home_assistant
Set this to true if you want Home Assistant to be restarted if its
configuration was changed by this add-on.

## snips_console
You can configure your email address and password for logging into the Snips
Console.  If you do, the Web UI can be used to download and install your
assistant.  Note that the ZIP file for the installed assistant will also be
copied to the file specified in the [assistant](#assistant) option (in
/share/snips).

By using configuring your email address and password, you don't need to
manually download your assistant's ZIP file from the Snips Console before
starting this add-on.  Instead, you can start the add-on without an assistant,
and use the Web UI to select and install your assistant.

| Option | Values | Default |
|--------|--------|---------|
|[email](#email)|email address||
|[password](#password)|string||

### email
The email address for your Snips Console login.

### password
The password for your Snips Console login.  If you're running hassio build 186
or later, you can put your password in secrets.yaml, and set this to "!secret
&lt;password_identifier&gt; See
[Storing Secrets](https://www.home-assistant.io/docs/configuration/secrets/)
for more information.

## snips_extras
These are options snips programs you can run.

| Option | Values | Default |
|--------|--------|---------|
|[snips_analytics](#snips_analytics)|true, false|false|
|[snips_watch](#snips_watch)|true, false|false|

### snips_analytics
Set to true if you want to run snips-analytics.

### snips_watch
If true, snips-watch will be started.  Use the Logs tab of the Web UI to
view its output.

## tts
See [TTS Options](#tts-options) below.

# TTS Options
## Overview
Text-to-speech in this add-on is handled through a special script that can
make use of online services for vastly improved speech, improved speech
through mimic, or the default speech engine in snips.  When using an online
service, the script will check if the service appears to be available and if
the amount of text exceeds the usual limitations of the online service,
before trying that service, and won't bother trying if the request is likely
to fail.  For any failure, the next configured online service is tried,
until all configured online services have been tried.  If all of the
configured online services have failed, the script will use the configured
offline service.

To reduce the network load and potential costs of using online services, the
speech from online services is cached for later use.  See the max_cache_size
option for more information on the cache.

If you don't configure any online services, then the configured offline
service will always be used.

**Please note that speech from snips may contain sensitive information that
could be transmitted across the internet if you have configured online
services.**

The use of online text-to-speech services is inspired by the
[SnipsSuperTTS script](https://gist.github.com/Psychokiller1888/cf10af3220b5cd6d9c92c709c6af92c2),
but the script in this add-on was written from scratch to provide more
features.

| Option | Values | Default | 
|--------|--------|---------|
|[offline_service](#offline_service)|mimic, pico2wave|mimic|
|[mimic_voice](#mimic_voice)|file name|/share/snips/voices/cmu_us_eey.flitevox|
|[online_services](#online_services)|array|an empty array|
|[max_cache_size](#max_cache_size)|integer or string|50MB|
|[sample_rate](#sample_rate)|integer|22050|
|[online_volume_factor](#online_volume_factor)|float|0.25|
|[macos_voice](#macos_voice)|string|Susan|
|[macos_ssh_config](#macos_ssh_config)|file name|/config/ssh/ssh_config
|[macos_ssh_host](#macos_ssh_host)|string||
|[google_voice](#google_voice)|string|Wavenet-F|
|[google_voice_gender](#google_voice_gender)|MALE, FEMALE|FEMALE|
|[google_tts_key](#google_tts_key)|string||
|[amazon_voice](#amazon_voice)|string|Joanna|
|[aws_access_key_id](#aws_access_key_id)|string||
|[aws_secret_access_key](#aws_secret_access_key)|string||
|[aws_default_region](#aws_default_region)|string||

## offline_service
You can set this option to either "mimic" or "pico2wave".  mimic can provide
higher quality voices than pico2wave.  pico2wave is what snips will use by
default.

## mimic_voice
This is the full path to the flitevox file to use for mimic.  I recommend
placing the file in /share/snips/ for easy access.

Please note that only one flitevox file (voice) for mimic is included in the
image.  You an download additional voices at
[http://festvox.org/flite/packed/flite-2.1/voices/](http://festvox.org/flite/packed/flite-2.1/voices/)

## online_services
This is an array of online services to try.  They will be tried in the order
in which they appear in this array.  Make sure this is an empty array if you
don't want your speech to be sent to the internet.

You can configure "macos", "google_translate", "google", or "amazon".  Each
are described below.

### macos
This option lets you use the text-to-speech features of macOS from one of
your own computers.  The computer must be running macOS, and have ssh
(Remote Login) enabled and properly configured.  See the macos_voice,
macos_ssh_config, and macos_ssh_host options for more information.

Unlike the other online services, the macos service doesn't send data to
the internet -- unless you choose a macOS system that isn't on your local
network.

Since this runs on your own computer, it's free to use, but requires you to
keep your mac running any time you want to use snips, which may cost more in
electrical bills.

### google_translate (Google Translate Text-to-Speech)
This service is limited to only 100 bytes of text at a time, and may have
other limitations, possibly including limitations based on your location.
This service is provided for free, but could be removed at any time.

### google (Google Cloud Text-to-Speech)
This service is limited to 5000 bytes of text at a time.  This service is
not free, and requires registration with Google.  See
[https://cloud.google.com/text-to-speech/docs/quickstart-protocol](https://cloud.google.com/text-to-speech/docs/quickstart-protocol)
to register, and
[https://console.developers.google.com/](https://console.developers.google.com/)
to retrieve the API key.

Since this is a paid service, it does not receive regular testing by the
add-on author.

### amazon (Amazon Polly)
This service is limited to 3000 bytes of text at a time.  This service is
not free, and requires registration with Amazon. See
[https://aws.amazon.com/polly/getting-started/?nc=sn&loc=5](https://aws.amazon.com/polly/getting-started/?nc=sn&loc=5)
to get started.

This service also requires extra software to be installed.  If the amazon
service is configured, and the extra software is not installed, it will be
downloaded and installed.  This download and installation will happen every
time you update this add-on.

Since this is a paid service, it does not receive regular testing by the
add-on author.

## max_cache_size
Speech from an online service is cached to speed up responses, but may be
removed when updating this add-on.  You can also set a limit for how large
the cache can grow.

This value can be a number of bytes, or a number followed by KB, MB, or GB.
For example, to limit the cache to 50 megabytes, you would set
max_cache_size to "50MB".

Please note this is approximate, as the cache is checked only once an hour.
If you want to let the cache grow without bounds, set this option to 0.

## sample_rate
With the google and amazon services, you can choose a sample rate which
affects the quality of the speech that is cached.  For all online services,
this is also the sample rate for the speech that is played by snips.  This
option is a whole number, in Hz.  Unless you have some really special
requirements, you probably want to stick with the default of 22050.

## online_volume_factor
The online services tend to produce speech that is much louder than that
produced by mimic or pico2wave.  Since volume controls in snips are often
difficult and you don't necessarily know if the speech will come from an
online service, this option lets you adjust the volume for online services.

Choosing a value between 0 and 1 will decrease the volume, while larger
values will increase it.  For example, setting this to "0.5" will reduce the
volume to 50% of the original, "0.25" will reduce the volume to 25%, "1.5"
will increase the volume by 50%, and "2.0" will increase the volume to 2
times the original. 

## macos_voice
This is the macos voice you want to use with macOS.  To view the list of
choices available, choose "Accessibility" in the System Preferences App.
Then click on the Speech category on the left side.  Your choices are in the
System Voice drop list.  If you choose "Customize..." you can install other
voices, and hear samples of them.  You do not need to check the boxes for
"Enable announcements" or "Speak selected text when the key is pressed" for
this to work.

## macos_ssh_config
This is the full path to an OpenSSH config file which specifies how to
connect to your mac system.  It will typically look something like this:

```ssh_config
Host mymac
	User myname
	HostName FQDN or IP address of mymac
	ChallengeResponseAuthentication no
	GlobalKnownHostsFile /config/ssh/known_hosts
	IdentityFile /config/ssh/id_rsa
	PasswordAuthentication no
	StrictHostKeyChecking yes
```

This file is usually kept in /config/ssh, but you can also put it in
/share/snips, or anywhere in /share or /config.  Be sure the path references
in the file are correct and exist.

Note that unless you bypass the new Hass.io DNS restrictions, you'll
probably need to use the IP address of your mac for the HostName setting.
Also, if StrictHostKeyChecking is yes, you'll need to manually add the host
key for your mac to the GlobalKnownHostsFile.

You will need to ensure that your IdentityFile is not protected by a
password.  This means that anything which can view that file can connect to
your mac and run programs on it.  I recommend creating a new "Managed with
Parental Controls" user for this purpose.  The user needs to be able to run
/usr/bin/say.

## macos_ssh_host
This is the host name of your mac, and must match the Host entry in the
macos_ssh_config file.

## google_voice
This is the voice to use for Google's Cloud Text-to-Speech service.  This is
usually something like "Wavenet-A", "Wavenet-B", etc., for the high quality
voices.  See
[https://cloud.google.com/text-to-speech/docs/voices](https://cloud.google.com/text-to-speech/docs/voices)
for more info.

## google_voice_gender
This should be set to "MALE" for male voices, or "FEMALE" for a female
voice.

## google_tts_key
This is your API key for Google's Cloud Text-to-Speech service.

## amazon_voice
This is the voice to use for Amazon's Polly service.  See
[https://docs.aws.amazon.com/polly/latest/dg/voicelist.html](https://docs.aws.amazon.com/polly/latest/dg/voicelist.html)
for more info.

## amazon_access_key_id
## amazon_secret_access_key
## amazon_default_region
