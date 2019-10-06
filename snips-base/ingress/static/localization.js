/*
The MIT License (MIT)

Copyright (c) 2013 <Philippe Lang>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Modified by TOM to no longer dependon JQuery
// Modified by TOM to use language without country code before using fall-back
// language
// Modified by TOM to remove console.log messages.

Localization = function(dictionary, fallback_language, override) {
    this.dictionary = dictionary;
    this.fallback_language = fallback_language;
    if (override)
    {
        this.language = fallback_language;
        this.apply_to_current_html();
    }
    else
    {
        if (window.Intl && typeof window.Intl === 'object')
        {
            this.get_preferred_language_callback({ value: navigator.language });
        }
        else
        {
            navigator.globalization.getPreferredLanguage(
                this.get_preferred_language_callback,
                this.get_preferred_language_error_callback);
        }
    }
    return this;
};

Localization.prototype.get_preferred_language_callback = function(language) {
    this.language = language.value;
    if (!(this.language in this.dictionary))
    {
        this.language = this.language.match(/(.*)-.*/)[1];
        if (!(this.language in this.dictionary))
        {
            this.language = this.fallback_language;
        }
    }
    return this.apply_to_current_html();
};

Localization.prototype.get_preferred_language_error_callback = function() {
    this.language = this.fallback_language;
    return this.apply_to_current_html();
};

Localization.prototype.apply_to_current_html = function() {
    var key, value, _ref, _results;
    _ref = this.dictionary[this.language];
    _results = [];
    for (key in _ref)
    {
        value = _ref[key];
        var els = document.getElementsByClassName('l10n-' + key);
        for (var idx = 0; idx < els.length; idx++)
        {
            _results.push(els[idx].innerHTML = value);
        }
    }
    return _results;
};

Localization.prototype['for'] = function(key) {
    return this.dictionary[this.language][key];
};
