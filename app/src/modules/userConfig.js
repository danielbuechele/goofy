// This module makes a singleton configuration instance available for all other modules

const Store = require('electron-store');
const store = new Store();

module.exports = {
	SPELL_CHECK_ENABLED: 'spellCheck.enabled',
	SPELL_CHECK_LOCALE: 'spellCheck.locale',
	
	DOMAIN: 'root_domain',
	DEFAULT_DOMAIN: 'messenger.com/login',
	DOMAIN_FACEBOOK: 'facebook.com/messages',

	PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE: 'pushNotifications.showUnreadBadge',  // Default true
	PUSH_NOTIFICATIONS_HIDE_MESSAGE_BODY: 'pushNotifications.hideMessageBody',  // Default false

	PRIVACY_BLOCK_TYPING_INDICATOR: 'privacy.blockTypingIndicator',  // Default false
	PRIVACY_BLOCK_SEEN_INDICATOR: 'privacy.blockSeenIndicator',  // Default false

	store,
};
