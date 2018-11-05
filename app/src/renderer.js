const { BrowserWindow, app, shell } = require('electron').remote;
const remote = require('electron').remote;
const { Menu, autoUpdater, dialog, TouchBar } = remote;
const defaultMenu = require('electron-default-menu');
const fs = require('fs');
const css = fs.readFileSync(__dirname + '/assets/fb.css', 'utf-8');
const env = require('./config/env.js');
const userConfig = require('./modules/userConfig');
const constants = require('./helpers/constants');
const FocusHandler = require('./modules/focusHandler');
let loginWindow;

const getURL = (domain = userConfig.get('domain')) =>
	env.product === constants.PRODUCT_WWW ? 'https://www.facebook.com/messages' : `https://${domain}.facebook.com/chat`;

onload = () => {
	document.getElementById('logo').setAttribute('src', `./assets/${env.product}.png`);
	const webview = document.getElementById('webview');
	const setup = document.getElementById('setup');
	const domain = userConfig.get('domain');
	const menu = defaultMenu(app);

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

	menu[0].submenu.splice(
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

	if (env.product === constants.PRODUCT_WWW) {
		document.getElementById('webview').setAttribute('src', getURL());
	}

	if (domain || env.product === constants.PRODUCT_WWW) {
		menu[1].submenu.push(
			{
				type: 'separator',
			},
			{
				label: env.product === constants.PRODUCT_WWW ? 'Logout' : `Logout from “${domain}”`,
				click() {
					const c = webview.getWebContents().session.cookies;
					c.get({}, (error, cookies) => {
						for (var i = cookies.length - 1; i >= 0; i--) {
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
				},
			}
		);
		document.getElementById('webview').setAttribute('src', getURL());
	} else {
		setup.className = 'active';
		setup.onsubmit = () => {
			let domain = setup.querySelector('input').value.trim();
			userConfig.set('domain', domain);
			document.getElementById('webview').setAttribute('src', getURL());
		};
	}

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

	Menu.setApplicationMenu(Menu.buildFromTemplate(menu));

	webview.addEventListener('did-stop-loading', () => {
		if (webview.getURL().startsWith(getURL())) {
			webview.className = '';
		}
	});

	webview.addEventListener('dom-ready', () => {
		webview.insertCSS(css);
		if (env.name === 'development') {
			webview.openDevTools();
		}
	});

	webview.addEventListener('ipc-message', e => {
		if (e.channel === constants.DOCK_COUNT) {
			app.setBadgeCount(e.args[0]);
		} else if (e.channel === constants.TOUCH_BAR) {
			try {
				const data = JSON.parse(e.args[0]);
				remote.getCurrentWindow().setTouchBar(
					new TouchBar(
						data.map(
							({ name, active, unread, id }) => new TouchBar.TouchBarButton({
								label: unread ? `💬 ${name}` : name,
								backgroundColor: active ? '#0084FF' : undefined,
								click: () => {
									webview.send(constants.JUMP_TO_CONVERATION, id);
								},
							})
						)
					)
				);
			} catch (e) {
				//
			}
		}
	});

	webview.addEventListener('did-get-redirect-request', ({ oldURL, newURL }) => {
		if (oldURL.startsWith(getURL()) && newURL.indexOf('/login') > -1) {
			loginWindow = new BrowserWindow({
				parent: remote.getCurrentWindow(),
				show: false,
				minimizable: false,
				maximizable: false,
				webPreferences: {
					nodeIntegration: false,
				},
			});
			loginWindow.loadURL(oldURL);
			loginWindow.once('ready-to-show', () => {
				loginWindow.show();
			});
			loginWindow.webContents.on('will-navigate', (e, url) => {
				if (url.startsWith(getURL())) {
					loginWindow.close();
					webview.loadURL(getURL());
				}
			});
		} else if (newURL.startsWith(getURL()) && loginWindow) {
			loginWindow.close();
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
					webview.send(constants.JUMP_TO_CONVERATION, 'row_header_id_user:' + id);
				}
				break;
			}
		}
	});

	// Ensure focus propagates when the application is focused
	const webviewFocusHandler = new FocusHandler(webview);
	app.on('browser-window-focus', webviewFocusHandler);
};
