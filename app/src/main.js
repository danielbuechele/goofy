'use strict';

const electron = require('electron');
const { 
	BrowserWindow, 
	autoUpdater, 
	dialog, 
	Notification,
	app,
	session, 
	ipcMain, 
	nativeImage,
	shell,
} = electron;
const path = require('path');
const fs = require('fs');
const windowStateKeeper = require('electron-window-state');

const env = require('./config/env.js');
const constants = require('./helpers/constants');
const userConfig = require('./modules/userConfig');
const store = userConfig.store;
const RequestFilter = require('./modules/requestFilter');
const setupMenu = require('./menu');
const setupTouchBar = require('./touch_bar');

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;
let willQuitApp = false;

app.setName(env.appName);
app.disableHardwareAcceleration();

// goofy:// deep link
app.setAsDefaultProtocolClient('goofy');
app.on('open-url', (event, url) => {
	const parsedURL = new URL(url);
	switch(parsedURL.hostname) {
		case 'message': {
			const id = parsedURL.searchParams.get('id');
			if (id) {
				mainWindow.webContents.send(constants.JUMP_TO_CONVERSATION, 'row_header_id_user:' + id);
			}
			break;
		}
	}
});

function createWindow() {
	let mainWindowState = windowStateKeeper({
		defaultWidth: 800,
		defaultHeight: 600,
	});
	
	// Open the app at the same screen position and size as last time, if possible
	const options = { 
		x: mainWindowState.x,
		y: mainWindowState.y,
		width: mainWindowState.width,
		height: mainWindowState.height,
		titleBarStyle: 'hiddenInset', 
		title: 'Goofy', 
		webPreferences: {
			nodeIntegration: false,
			preload: path.join(__dirname, 'fb.js'),
		},
	};

	mainWindow = new BrowserWindow(options);
	mainWindowState.manage(mainWindow);

	// Propagate retina resolution to requests if necessary
	const requestFilter = new RequestFilter(session);
	const display = electron.screen.getPrimaryDisplay();
	const scaleFactor = display.scaleFactor;
	if (scaleFactor !== 1.0) {
		requestFilter.setRetinaCookie(scaleFactor);
	}

	mainWindow.loadURL(`https://${store.get(userConfig.DOMAIN, userConfig.DEFAULT_DOMAIN)}`);

	// Handle app closing
	mainWindow.on('close', e => {
		if (willQuitApp) {
			// the user tried to quit the app
			mainWindow = null;
			return;
		}

		// the user only tried to close the window
		e.preventDefault();
		if (!mainWindow) {
			return;
		}

		if (!mainWindow.isFullScreen()) {
			mainWindow.hide();
			return;
		}

		mainWindow.setFullScreen(false);
		// Wait for full screen animation to finish before hiding
		setTimeout(
			() => {
				mainWindow.hide();
			},
			1000
		);
	});

	// Misc

	setupMenu(mainWindow.webContents);
	setupTouchBar(mainWindow);
	
	mainWindow.webContents.on('dom-ready', () => {
		mainWindow.webContents.insertCSS(fs.readFileSync(path.join(__dirname, '/assets/fb.css'), 'utf8'));
	});

	mainWindow.webContents.on('new-window', (event, url, frameName, disposition, options) => {
		event.preventDefault();

		if (url === 'about:blank') {
			if (frameName !== 'about:blank') {
				options.titleBarStyle = 'default';
				options.webPreferences.nodeIntegration = false;
				event.newGuest = new electron.BrowserWindow(options);
			}
		} else {
			shell.openExternal(url);
		}
	});
}

// App lifecycle

app.on('ready', createWindow);

app.on('before-quit', () => willQuitApp = true);

// Quit when all windows are closed.
app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') {
		app.quit();
	}
});

app.on('activate', function() {
	// On OS X it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (mainWindow) {
		mainWindow.show();
	} else {
		createWindow();
	}
});

// Notifications / unread badge

ipcMain.on(constants.NEW_MESSAGE_NOTIFICATION, (event, params) => {
	if (!store.get(userConfig.PUSH_NOTIFICATIONS_ENABLED, true)) {
		return;
	}

	const notifParams = params.notifParams;
	notifParams.icon = nativeImage.createFromDataURL(params.iconDataUrl);

	if (store.get(userConfig.PUSH_NOTIFICATIONS_HIDE_MESSAGE_BODY, false)) {
		notifParams.body = '[Hidden]';
	}

	let notification = new Notification(notifParams);
	notification.on('click', () => {
		if (mainWindow) {
			mainWindow.show();
		}
		event.sender.send(constants.JUMP_TO_CONVERSATION_BY_IMAGE_NAME, params.imageName);
	});
	notification.show();
});

ipcMain.on(constants.DOCK_COUNT, (event, params) => {
	if (!store.get(userConfig.PUSH_NOTIFICATIONS_ENABLED, true) || !store.get(userConfig.PUSH_NOTIFICATIONS_SHOW_UNREAD_BADGE, true)) {
		return;
	}
	app.setBadgeCount(params);
});

// Auto-update

autoUpdater.on('update-downloaded', (event, releaseNotes, releaseName) => {
	dialog.showMessageBox(
		{
			type: 'info',
			title: 'Update available',
			message: `A new version of ${env.appName} is available!`,
			detail: `${env.appName} ${releaseName} is now available—you have ${app.getVersion()}.  Restart the application to apply updates.`,
			buttons: [ 'Restart', 'Later' ],
		},
		(response) => {
			if (response === 0) {
				willQuitApp = true;
				autoUpdater.quitAndInstall();
			}
		}
	);
});

if (env.name === 'production') {
	autoUpdater.setFeedURL(`${env.updateURL}/${process.platform}-${process.arch}/${app.getVersion()}`);
	autoUpdater.checkForUpdates();
}
