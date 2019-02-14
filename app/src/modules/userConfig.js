// This module makes a singleton configuration instance available for all other modules

const Store = require('electron-store');
const store = new Store();

module.exports = {
    WINDOW_LAYOUT: 'windowLayout',
    
    SPELL_CHECK_ENABLED: 'SPELL_CHECK_ENABLED',
    SPELL_CHECK_LOCALE: 'SPELL_CHECK_LOCALE',
    
    DOMAIN: 'DOMAIN',
    DEFAULT_DOMAIN: 'messenger.com/login',
    DOMAIN_FACEBOOK: 'facebook.com/messages',

    store
};
