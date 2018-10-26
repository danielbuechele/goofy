// This module makes a singleton configuration instance available for all other modules

const Config = require('electron-config');
const constants = require('../helpers/constants');
const userConfig = new Config();

//Set default value
if (typeof userConfig.get(constants.SETTINGS_MESSAGE_PREVIEW) === 'undefined') {
	userConfig.set(constants.SETTINGS_MESSAGE_PREVIEW, true);
}

module.exports = userConfig;
