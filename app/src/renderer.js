'use strict';

const remote = require('electron').remote;
const { app, shell, TouchBar } = remote;
const fs = require('fs');
const css = fs.readFileSync(__dirname + '/assets/fb.css', 'utf-8');

const constants = require('./helpers/constants');
const FocusHandler = require('./modules/focusHandler');
const setupMenu = require('./menu');
const setupTouchBar = require('./touch_bar');

onload = () => {
	setupMenu();
	
	document.getElementById('logo').setAttribute('src', `./assets/www.png`);

	const webview = document.getElementById('webview');
	
	webview.setAttribute('src', 'https://www.messenger.com/login');

	webview.addEventListener('did-stop-loading', () => {
		webview.className = '';
	});

	webview.addEventListener('dom-ready', () => {
		webview.insertCSS(css);
		setupTouchBar();
	});

	webview.addEventListener('ipc-message', e => {
		if (e.channel === constants.DOCK_COUNT) {
			app.setBadgeCount(e.args[0]);
		}
	});

	webview.addEventListener('new-window', ({ url }) => {
		shell.openExternal(url);
	});

	app.setAsDefaultProtocolClient('goofy');
	app.on('open-url', (event, url) => {
		const parsedURL = new URL(url);
		switch(parsedURL.pathname) {
			case '//message': {
				const id = parsedURL.searchParams.get('id');
				if (id) {
					webview.send(constants.JUMP_TO_CONVERSATION, 'row_header_id_user:' + id);
				}
				break;
			}
		}
	});

	// Ensure focus propagates when the application is focused
	const webviewFocusHandler = new FocusHandler(webview);
	app.on('browser-window-focus', webviewFocusHandler);
};
