// This module makes a singleton configuration instance available for all other modules

const Config = require('electron-config');
const userConfig = new Config();

module.exports = userConfig;
