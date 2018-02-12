const fs = require('fs');
const css = fs.readFileSync(__dirname + '/assets/menu.css', 'utf-8');
const Config = require('electron-config');
const userConfig = new Config();
const env = require('./config/env.js');
const remote = require('electron').remote;
const getMenuBarIconPath = require('./helpers/getMenuBarIconPath');
const constants = require('./helpers/constants');

onload = () => {
	const webview = document.getElementById('webview');
	let domain = userConfig.get('domain');
	if (domain) {
		document.getElementById('webview').setAttribute('src', `https://${domain}.facebook.com`);
		webview.addEventListener('dom-ready', () => {
			webview.insertCSS(css);
			if (env.name === 'development') {
				webview.openDevTools();
			}
		});

		webview.addEventListener('ipc-message', (e) => {
			if (e.channel === constants.NOTIFICATION_COUNT && remote.getGlobal('sharedObject').mb) {
				const unread = parseInt(e.args[0]);
				remote.getGlobal('sharedObject').unread = unread;
				remote.getGlobal('sharedObject').mb.tray.setImage(getMenuBarIconPath(false, unread));
			}
		});
	}
};
