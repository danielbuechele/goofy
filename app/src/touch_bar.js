'use strict';

const electron = require('electron');
const { TouchBar } = electron;

const constants = require('./constants');

function setupTouchBar(browserWindow) {
	browserWindow.setTouchBar(
		new TouchBar(
			[
				new TouchBar.TouchBarButton({
					label: '📝',
					click: () => {
						browserWindow.webContents.send(constants.NEW_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🤫',
					click: () => {
						browserWindow.webContents.send(constants.MUTE_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🗄',
					click: () => {
						browserWindow.webContents.send(constants.ARCHIVE_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🗑',
					click: () => {
						browserWindow.webContents.send(constants.DELETE_CONVERSATION);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '🔵',
					click: () => {
						browserWindow.webContents.send(constants.MARK_CONVERSATION_UNREAD);
					},
				}),
				new TouchBar.TouchBarButton({
					label: '👍',
					click: () => {
						browserWindow.webContents.send(constants.LIKE_CONVERSATION);
					},
				}),
			]
		)
	);
}

module.exports = setupTouchBar;
