// This module makes a singleton configuration instance available for all other modules

const Store = require('electron-store');
const store = new Store();

module.exports = {
	WINDOW_LAYOUT: 'windowLayout',
	
	SPELL_CHECK_ENABLED: 'spellCheck.enabled',
	SPELL_CHECK_LOCALE: 'spellCheck.locale',
	
	DOMAIN: 'root_domain',
	DEFAULT_DOMAIN: 'messenger.com/login',
	DOMAIN_FACEBOOK: 'facebook.com/messages',

	PUSH_NOTIFICATIONS_ENABLED: 'pushNotifications.enabled',
	PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE: 'pushNotifications.showUnreadBadge',

	store,
};
