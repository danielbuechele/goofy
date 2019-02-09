const remote = require('electron').remote;
const { app, shell, Menu, autoUpdater, dialog, TouchBar } = remote;
const defaultMenu = require('electron-default-menu');
const fs = require('fs');
const css = fs.readFileSync(__dirname + '/assets/fb.css', 'utf-8');

const env = require('./config/env.js');
const userConfig = require('./modules/userConfig');
const constants = require('./helpers/constants');
const FocusHandler = require('./modules/focusHandler');

const getURL = (domain = userConfig.get('domain')) =>
	env.product === constants.PRODUCT_WWW ? 'https://www.messenger.com/login' : `https://${domain}.facebook.com/chat`;

onload = () => {
	setupMenu();
	
	document.getElementById('logo').setAttribute('src', `./assets/${env.product}.png`);

	const webview = document.getElementById('webview');
	
	if (env.product === constants.PRODUCT_WWW) {
		webview.setAttribute('src', getURL());
	}

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

function setupMenu() {
	const menu = defaultMenu(app, shell);
	const webview = document.getElementById('webview');

	// File menu
	menu.splice(menu.findIndex(item => item.label === 'Edit'), 0, {
		label: 'File',
		submenu: [
			{
				label: 'New Conversation',
				accelerator: 'CmdOrCtrl+N',
				click() {
					webview.send(constants.NEW_CONVERSATION);
				},
			},
		],
	});

	const domain = userConfig.get('domain');
	if (domain || env.product === constants.PRODUCT_WWW) {
		menu[1].submenu.push(
			{
				type: 'separator',
			},
			{
				label: env.product === constants.PRODUCT_WWW ? 'Logout' : `Logout from “${domain}”`,
				click() {
					logout();
				},
			}
		);
		webview.setAttribute('src', getURL());
	} else {
		const setup = document.getElementById('setup');
		setup.className = 'active';
		setup.onsubmit = () => {
			const domain = setup.querySelector('input').value.trim();
			userConfig.set('domain', domain);
			webview.setAttribute('src', getURL());
		};
	}

	// Main menu
	let mainMenu = menu[0];
	mainMenu.submenu.splice(
		1,
		0,
		{
			type: 'separator',
		},
		{
			label: 'Preferences...',
			accelerator: 'CmdOrCtrl+,',
			click() {
				webview.send(constants.SHOW_SETTINGS);
			},
		}
	);

	if (env.name === 'production') {
		menu[0].submenu.splice(1, 0, {
			label: 'Check for Update',
			click() {
				autoUpdater.on('update-not-available', () => {
					autoUpdater.removeAllListeners('update-not-available');
					dialog.showMessageBox({
						message: 'No update available',
						detail: `${env.appName} ${app.getVersion()} is the latest version available.`,
						buttons: [ 'OK' ],
					});
				});
				autoUpdater.checkForUpdates();
			},
		});
	}

	// Fix incorrect accelerator for "Hide Others" (imported from defaultMenu())
	mainMenu.submenu[mainMenu.submenu.findIndex(item => item.label === 'Hide Others')].accelerator = 'Command+Option+H';

	// View menu
	let viewMenu = menu[menu.findIndex(item => item.label === 'View')];
	viewMenu.submenu.splice(
		0,
		0,
		{
			type: 'separator',
		},
		{
			label: 'Inbox',
			accelerator: 'CmdOrCtrl+1',
			click() {
				webview.send(constants.SHOW_MESSAGE_LIST_INBOX);
			},
		},
		{
			label: 'Active contacts',
			accelerator: 'CmdOrCtrl+2',
			click() {
				webview.send(constants.SHOW_MESSAGE_LIST_ACTIVE_CONTACTS);
			},
		},
		{
			label: 'Message requests',
			accelerator: 'CmdOrCtrl+3',
			click() {
				webview.send(constants.SHOW_MESSAGE_LIST_MESSAGE_REQUESTS);
			},
		},
		{
			label: 'Archived threads',
			accelerator: 'CmdOrCtrl+4',
			click() {
				webview.send(constants.SHOW_MESSAGE_LIST_ARCHIVED_THREADS);
			},
		},
		{
			type: 'separator',
		}
	);

	if (env.name === 'development') {
		viewMenu.submenu.splice(
			viewMenu.submenu.length,
			0,
			{
				type: 'separator',
			},
			{
				label: 'Developer tools (inner webview)',
				click() {
					webview.openDevTools();
				},
			},
			{
				type: 'separator',
			}
		);
	}

	// Conversation menu
	menu.splice(menu.findIndex(item => item.label === 'Window'), 0, {
		label: 'Conversation',
		submenu: [
			{
				label: 'Mute',
				accelerator: 'CmdOrCtrl+shift+M',
				click() {
					webview.send(constants.MUTE_CONVERSATION);
				},
			},
			{
				type: 'separator',
			},
			{
				label: 'Archive',
				accelerator: 'CmdOrCtrl+shift+A',
				click() {
					webview.send(constants.ARCHIVE_CONVERSATION);
				},
			},
			{
				label: 'Delete',
				accelerator: 'CmdOrCtrl+shift+D',
				click() {
					webview.send(constants.DELETE_CONVERSATION);
				},
			},
			{
				type: 'separator',
			},
			{
				label: 'Mark as Unread/Read',
				accelerator: 'CmdOrCtrl+shift+U',
				click() {
					webview.send(constants.MARK_CONVERSATION_UNREAD);
				},
			},
			{
				label: 'Mark as Spam',
				click() {
					webview.send(constants.MARK_CONVERSATION_SPAM);
				},
			},
			{
				label: 'Report Spam or Abuse',
				click() {
					webview.send(constants.REPORT_CONVERSATION_SPAM_OR_ABUSE);
				},
			},
		],
	});

	// Window Menu
	let windowMenu = menu[menu.findIndex(item => item.label === 'Window')];
	windowMenu.submenu.push(
		{
			label: 'Select Next Conversation',
			accelerator: 'CmdOrCtrl+]',
			click() {
				webview.send(constants.NEXT_CONVERSATION);
			},
		},
		{
			label: 'Select Previous Conversation',
			accelerator: 'CmdOrCtrl+[',
			click() {
				webview.send(constants.PREV_CONVERSATION);
			},
		},
		{
			type: 'separator',
		}
	);

	// Help Menu
	let helpMenu = menu[menu.findIndex(item => item.label === 'Help')];
	helpMenu.submenu[helpMenu.submenu.findIndex(item => item.label === 'Learn More')].click = function() { 
		// Load goofy website
		shell.openExternal('https://www.goofyapp.com') 
	}

	if (env.product === constants.PRODUCT_WORKPLACE) {
		windowMenu.submenu.push({
			label: 'Show notifications in menu bar',
			type: 'checkbox',
			checked: userConfig.get('menubar'),
			click() {
				userConfig.set('menubar', !userConfig.get('menubar'));
				remote.app.relaunch();
				remote.app.exit(0);
			},
		});
	}

	Menu.setApplicationMenu(Menu.buildFromTemplate(menu));
}

function setupTouchBar() {
	const webview = document.getElementById('webview');
	remote.getCurrentWindow().setTouchBar(
		new TouchBar(
			[
				new TouchBar.TouchBarButton({
					label: '📝',
					click: () => {
						webview.send(constants.NEW_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🤫',
					click: () => {
						webview.send(constants.MUTE_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🗄',
					click: () => {
						webview.send(constants.ARCHIVE_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🗑',
					click: () => {
						webview.send(constants.DELETE_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🔵',
					click: () => {
						webview.send(constants.MARK_CONVERSATION_UNREAD);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '👍',
					click: () => {
						webview.send(constants.LIKE_CONVERSATION);
					},
				}),
			]
		)
	);
}

function logout() {
	const webview = document.getElementById('webview');
	const c = webview.getWebContents().session.cookies;
	c.get({}, (error, cookies) => {
		for (let i = cookies.length - 1; i >= 0; i--) {
			const { name, domain, path, secure } = cookies[i];
			const url = 'http' + (secure ? 's' : '') + '://' + domain + path;
			c.remove(url, name, () => {});
		}
	});

	// this waits for all cookies to be removed, it would be nicer to wait for all callbacks to be called
	setTimeout(
		() => {
			if (env.product === constants.PRODUCT_WORKPLACE) {
				userConfig.delete('domain');
			}
			app.relaunch();
			app.exit(0);
		},
		500
	);
}
