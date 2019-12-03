'use strict';

const { ipcRenderer } = require('electron');

const constants = require('./helpers/constants');

/**
 * Hijack WebView notifications and create our own
 */
function overrideWindowNotification() {
	window.Notification = (notification => {
		const EmptyNotification = function (rawTitle, options) {
			const rawBody = options.body;
			const title = (typeof rawTitle === 'object' && rawTitle.props) ? rawTitle.props.content[0] : rawTitle;
			const body = rawBody.props ? rawBody.props.content[0] : rawBody;
			const icon = options.icon;
			
			const image = new Image();
			image.crossOrigin = 'anonymous';
			image.src = icon;
	
			image.addEventListener('load', () => {
				const canvas = document.createElement('canvas');
				canvas.width = image.width;
				canvas.height = image.height;
				
				const context = canvas.getContext('2d');
				context.drawImage(image, 0, 0, image.width, image.height);
	
				const imageName = icon.substring(icon.lastIndexOf('/') + 1, icon.indexOf('?'));
	
				ipcRenderer.send(
					constants.NEW_MESSAGE_NOTIFICATION, 
					{
						notifParams: {
							title,
							body: body,
							silent: options.silent,
						},
						iconDataUrl: canvas.toDataURL(),
						imageName,
					}
				);
			});
	
			return false;
		};
		
		return Object.assign(EmptyNotification, notification);
	
	})(window.Notification);
}

function bindLoadMessageIPCMessages() {
	ipcRenderer.on(constants.JUMP_TO_CONVERSATION, (event, id) => {
		const conversation = document.querySelector(`[id='${id}'] a`);
		if (conversation) {
			conversation.click();
		}
	});
	
	ipcRenderer.on(constants.JUMP_TO_CONVERSATION_BY_IMAGE_NAME, (event, imageName) => {
		const conversation = document.querySelector(`div[role="navigation"] > div > ul img[src*="${imageName}"]`);
		if (conversation) {
			conversation.click();
		}
	});
}

function bindDock() {
	document.addEventListener('DOMContentLoaded', () => {
		const titleObserver = new MutationObserver(mutations => {
			mutations.forEach((mutation) => {
				const title = mutation.target.text;
				if (title === 'Messenger') {
					// All notifications cleared, set to zero.
					//
					// Note, seems like most languages reset title back to "Messenger" 
					// after notifications cleared
					ipcRenderer.send(constants.DOCK_COUNT, 0);
					return;
				}
				
				if (!title.startsWith('(')) {
					// Flickers between "x messaged you" and "(x) Messenger".
					//
					// Note: We don't check text fragment here as "messaged you" could 
					// be localized
					return;
				}

				const currentDockCount = parseInt(title.substr(1, (title.lastIndexOf(')') - 1))) || 0;
				ipcRenderer.send(constants.DOCK_COUNT, currentDockCount);
			});
		});
		
		titleObserver.observe(
			document.querySelector('title'), 
			{
				characterData: true,
				subtree: true,
				childList: true,
			}
		);
	});
}

function bindNotifications() {
	overrideWindowNotification();
	bindLoadMessageIPCMessages();
	bindDock();
}

module.exports = bindNotifications;
