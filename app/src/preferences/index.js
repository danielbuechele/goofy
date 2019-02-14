'use strict';

const userConfig = require('../modules/userConfig');
const store = userConfig.store

const SPELL_CHECK_ENABLED_CHECKBOX = '#spellCheckEnabled';
const SPELL_CHECK_LOCALE_SELECT = '#spellCheckLocaleSelect';
const DOMAIN_SELECT = '#domainSelect';

function loadSettingsToUI() {
    document.querySelector(SPELL_CHECK_ENABLED_CHECKBOX).checked = store.get(userConfig.SPELL_CHECK_ENABLED, true);

    const locale = store.get(userConfig.SPELL_CHECK_LOCALE, "");
    const languageSelectElem = document.querySelector(SPELL_CHECK_LOCALE_SELECT);
    if (locale === "en-GB") {
        languageSelectElem.selectedIndex = 1;
    } else if (locale === "en-US") {
        languageSelectElem.selectedIndex = 2;
    } else {
        languageSelectElem.selectedIndex = 0;
    }

    const domain = store.get(userConfig.DOMAIN, userConfig.DEFAULT_DOMAIN);
    const domainSelectElem = document.querySelector(DOMAIN_SELECT);
    if (domain === userConfig.DEFAULT_DOMAIN) {
        domainSelectElem.selectedIndex = 0;
    } else {
        domainSelectElem.selectedIndex = 1;
    }
}

function bindUI() {
    const spellCheckEnabledCheckboxElem = document.querySelector(SPELL_CHECK_ENABLED_CHECKBOX);
    spellCheckEnabledCheckboxElem.addEventListener('change', () => {
        store.set(userConfig.SPELL_CHECK_ENABLED, spellCheckEnabledCheckboxElem.checked);
        loadSettingsToUI();
    });
    
    const localeSelectElem = document.querySelector(SPELL_CHECK_LOCALE_SELECT);
    localeSelectElem.addEventListener('change', (e) => {
        store.set(userConfig.SPELL_CHECK_LOCALE, localeSelectElem.value);
        loadSettingsToUI();
    });
    
    const domainSelectElem = document.querySelector(DOMAIN_SELECT);
    domainSelectElem.addEventListener('change', (e) => {
        store.set(userConfig.DOMAIN, domainSelectElem.value);
        loadSettingsToUI();
    });
}

loadSettingsToUI();
bindUI();
