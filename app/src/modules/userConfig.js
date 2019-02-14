// This module makes a singleton configuration instance available for all other modules

const Store = require('electron-store');
const userConfig = new Store();

module.exports = userConfig;
