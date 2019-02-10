'use strict';

const remote = require('electron').remote;
const { TouchBar } = remote;

const constants = require('./helpers/constants');

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

module.exports = setupTouchBar;
