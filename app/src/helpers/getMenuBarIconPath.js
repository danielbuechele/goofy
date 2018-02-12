const electron = require('electron');
const path = require('path');
const os = require('os');

module.exports = (focus, unread) => {
	let mode = 'dark';
	const sysPrefs = electron.systemPreferences || electron.remote.systemPreferences;
	if (os.platform() === 'darwin' && !sysPrefs.isDarkMode() && !focus) {
		mode = 'light';
	}
	return path.join(__dirname, '..', 'assets', `menu-workplace-${mode}-${unread ? 'unread' : 'read'}.png`);
};
