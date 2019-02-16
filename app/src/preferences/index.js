'use strict';

const userConfig = require('../modules/userConfig');
const store = userConfig.store;

const SPELL_CHECK_ENABLED_CHECKBOX = '#spellCheckEnabled';
const SPELL_CHECK_LOCALE_SELECT = '#spellCheckLocaleSelect';

const PUSH_NOTIFS_ENABLED_CHECKBOX = '#pushNotifsEnabled';
const PUSH_NOTIFS_SHOW_UNREAD_BADGE_CHECKBOX = '#pushNotifsShowUnreadBadge';
const PUSH_NOTIFS_HIDE_MESSAGE_BODY_CHECKBOX = '#pushNotifsHideMessageBody';

const PRIVACY_BLOCK_TYPING_INDICATOR_CHECKBOX = '#privacyBlockTypingIndicator';
const PRIVACY_BLOCK_SEEN_INDICATOR_CHECKBOX = '#privacyBlockSeenIndicator';

const DOMAIN_SELECT = '#domainSelect';

function loadSettingsToUI() {
	// Spell check
	document.querySelector(SPELL_CHECK_ENABLED_CHECKBOX).checked = store.get(userConfig.SPELL_CHECK_ENABLED, true);

	const locale = store.get(userConfig.SPELL_CHECK_LOCALE, '');
	const languageSelectElem = document.querySelector(SPELL_CHECK_LOCALE_SELECT);
	if (locale === 'en-GB') {
		languageSelectElem.selectedIndex = 1;
	} else if (locale === 'en-US') {
		languageSelectElem.selectedIndex = 2;
	} else {
		languageSelectElem.selectedIndex = 0;
	}

	// Push notifications
	document.querySelector(PUSH_NOTIFS_ENABLED_CHECKBOX).checked = store.get(userConfig.PUSH_NOTIFICATIONS_ENABLED, true);
	document.querySelector(PUSH_NOTIFS_SHOW_UNREAD_BADGE_CHECKBOX).checked = store.get(userConfig.PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE, true);
	document.querySelector(PUSH_NOTIFS_HIDE_MESSAGE_BODY_CHECKBOX).checked = store.get(userConfig.PUSH_NOTIFICATIONS_HIDE_MESSAGE_BODY, false);

	// Privacy
	document.querySelector(PRIVACY_BLOCK_TYPING_INDICATOR_CHECKBOX).checked = store.get(userConfig.PRIVACY_BLOCK_TYPING_INDICATOR, false);
	document.querySelector(PRIVACY_BLOCK_SEEN_INDICATOR_CHECKBOX).checked = store.get(userConfig.PRIVACY_BLOCK_SEEN_INDICATOR, false);

	// Advanced
	const domain = store.get(userConfig.DOMAIN, userConfig.DEFAULT_DOMAIN);
	const domainSelectElem = document.querySelector(DOMAIN_SELECT);
	if (domain === userConfig.DEFAULT_DOMAIN) {
		domainSelectElem.selectedIndex = 0;
	} else {
		domainSelectElem.selectedIndex = 1;
	}
}

function bindUI() {
	// Spell check
	const spellCheckEnabledCheckboxElem = document.querySelector(SPELL_CHECK_ENABLED_CHECKBOX);
	spellCheckEnabledCheckboxElem.addEventListener('change', () => {
		store.set(userConfig.SPELL_CHECK_ENABLED, spellCheckEnabledCheckboxElem.checked);
		loadSettingsToUI();
	});
	
	const localeSelectElem = document.querySelector(SPELL_CHECK_LOCALE_SELECT);
	localeSelectElem.addEventListener('change', () => {
		store.set(userConfig.SPELL_CHECK_LOCALE, localeSelectElem.value);
		loadSettingsToUI();
	});

	// Push notifications
	const pushNotifEnabledCheckboxElem = document.querySelector(PUSH_NOTIFS_ENABLED_CHECKBOX);
	pushNotifEnabledCheckboxElem.addEventListener('change', () => {
		store.set(userConfig.PUSH_NOTIFICATIONS_ENABLED, pushNotifEnabledCheckboxElem.checked);
		loadSettingsToUI();
	});
	const pushNotifShowUnreadBadgeCheckboxElem = document.querySelector(PUSH_NOTIFS_SHOW_UNREAD_BADGE_CHECKBOX);
	pushNotifShowUnreadBadgeCheckboxElem.addEventListener('change', () => {
		store.set(userConfig.PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE, pushNotifShowUnreadBadgeCheckboxElem.checked);
		loadSettingsToUI();
	});
	const pushNotifHideMessageBodyCheckboxElem = document.querySelector(PUSH_NOTIFS_HIDE_MESSAGE_BODY_CHECKBOX);
	pushNotifHideMessageBodyCheckboxElem.addEventListener('change', () => {
		store.set(userConfig.PUSH_NOTIFICATIONS_HIDE_MESSAGE_BODY, pushNotifHideMessageBodyCheckboxElem.checked);
		loadSettingsToUI();
	});

	// Privacy
	const privacyBlockTypingIndicatorCheckboxElem = document.querySelector(PRIVACY_BLOCK_TYPING_INDICATOR_CHECKBOX);
	privacyBlockTypingIndicatorCheckboxElem.addEventListener('change', () => {
		store.set(userConfig.PRIVACY_BLOCK_TYPING_INDICATOR, privacyBlockTypingIndicatorCheckboxElem.checked);
		loadSettingsToUI();
	});
	const privacyBlockSeenIndicatorCheckboxElem = document.querySelector(PRIVACY_BLOCK_SEEN_INDICATOR_CHECKBOX);
	privacyBlockSeenIndicatorCheckboxElem.addEventListener('change', () => {
		store.set(userConfig.PRIVACY_BLOCK_SEEN_INDICATOR, privacyBlockSeenIndicatorCheckboxElem.checked);
		loadSettingsToUI();
	});

	// Advanced	
	const domainSelectElem = document.querySelector(DOMAIN_SELECT);
	domainSelectElem.addEventListener('change', () => {
		store.set(userConfig.DOMAIN, domainSelectElem.value);
		loadSettingsToUI();
	});
}

loadSettingsToUI();
bindUI();
