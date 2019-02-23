'use strict';

const userConfig = require('../modules/userConfig');
const store = userConfig.store;

const SPELL_CHECK_ENABLED_CHECKBOX = '#spellCheckEnabled';
const SPELL_CHECK_LOCALE_SELECT = '#spellCheckLocaleSelect';

const PUSH_NOTIFS_SHOW_UNREAD_BADGE_CHECKBOX = '#pushNotifsShowUnreadBadge';
const PUSH_NOTIFS_HIDE_MESSAGE_BODY_CHECKBOX = '#pushNotifsHideMessageBody';

const PRIVACY_BLOCK_TYPING_INDICATOR_CHECKBOX = '#privacyBlockTypingIndicator';
const PRIVACY_BLOCK_SEEN_INDICATOR_CHECKBOX = '#privacyBlockSeenIndicator';

const DOMAIN_SELECT = '#domainSelect';

function loadSettingsToUI() {
	// Spell check
	loadCheckboxSettingToUI(SPELL_CHECK_ENABLED_CHECKBOX, userConfig.SPELL_CHECK_ENABLED, true);

	const locale = store.get(userConfig.SPELL_CHECK_LOCALE, '');
	const localeSelectElem = document.querySelector(SPELL_CHECK_LOCALE_SELECT);

	let localeSelectedIndex = 0;
	for (let i = 0; i < localeSelectElem.options.length; i++) {
		const optionElem = localeSelectElem[i];
		if (optionElem.value === locale) {
			localeSelectedIndex = i;
			break;
		}
	}
	localeSelectElem.selectedIndex = localeSelectedIndex;

	// Push notifications
	loadCheckboxSettingToUI(PUSH_NOTIFS_SHOW_UNREAD_BADGE_CHECKBOX, userConfig.PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE, true);
	loadCheckboxSettingToUI(PUSH_NOTIFS_HIDE_MESSAGE_BODY_CHECKBOX, userConfig.PUSH_NOTIFICATIONS_HIDE_MESSAGE_BODY, false);

	// Privacy
	loadCheckboxSettingToUI(PRIVACY_BLOCK_TYPING_INDICATOR_CHECKBOX, userConfig.PRIVACY_BLOCK_TYPING_INDICATOR, false);
	loadCheckboxSettingToUI(PRIVACY_BLOCK_SEEN_INDICATOR_CHECKBOX, userConfig.PRIVACY_BLOCK_SEEN_INDICATOR, false);

	// Advanced
	const domain = store.get(userConfig.DOMAIN, userConfig.DEFAULT_DOMAIN);
	const domainSelectElem = document.querySelector(DOMAIN_SELECT);
	if (domain === userConfig.DEFAULT_DOMAIN) {
		domainSelectElem.selectedIndex = 0;
	} else {
		domainSelectElem.selectedIndex = 1;
	}
}

function loadCheckboxSettingToUI(checkboxSelector, storeKey, defaultVal) {
	document.querySelector(checkboxSelector).checked = store.get(storeKey, defaultVal);
}

function bindUI() {
	// Spell check
	bindCheckboxUI(SPELL_CHECK_ENABLED_CHECKBOX, userConfig.SPELL_CHECK_ENABLED);
	
	const localeSelectElem = document.querySelector(SPELL_CHECK_LOCALE_SELECT);
	localeSelectElem.addEventListener('change', () => {
		store.set(userConfig.SPELL_CHECK_LOCALE, localeSelectElem.value);
		loadSettingsToUI();
	});

	// Push notifications
	bindCheckboxUI(PUSH_NOTIFS_SHOW_UNREAD_BADGE_CHECKBOX, userConfig.PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE);
	bindCheckboxUI(PUSH_NOTIFS_HIDE_MESSAGE_BODY_CHECKBOX, userConfig.PUSH_NOTIFICATIONS_HIDE_MESSAGE_BODY);

	// Privacy
	bindCheckboxUI(PRIVACY_BLOCK_TYPING_INDICATOR_CHECKBOX, userConfig.PRIVACY_BLOCK_TYPING_INDICATOR);
	bindCheckboxUI(PRIVACY_BLOCK_SEEN_INDICATOR_CHECKBOX, userConfig.PRIVACY_BLOCK_SEEN_INDICATOR);

	// Advanced	
	const domainSelectElem = document.querySelector(DOMAIN_SELECT);
	domainSelectElem.addEventListener('change', () => {
		store.set(userConfig.DOMAIN, domainSelectElem.value);
		loadSettingsToUI();
	});
}

function bindCheckboxUI(checkboxSelector, storeKey) {
	const checkboxElem = document.querySelector(checkboxSelector);
	checkboxElem.addEventListener('change', () => {
		store.set(storeKey, checkboxElem.checked);
		loadSettingsToUI();
	});
}

loadSettingsToUI();
bindUI();
