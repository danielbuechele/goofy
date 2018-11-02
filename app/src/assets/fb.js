const { ipcRenderer } = require('electron');
const constants = require('../helpers/constants');
let latestMessages;
let isShowingInbox = false;

const NEW_MESSAGE_BUTTON = '._1enh ._36ic ._30yy._2oc8';
const UNREAD_MESSAGE_COUNT = '#mercurymessagesCountValue';
const MESSAGE_LIST = '._4u-c._9hq ul[role=grid]';
const MESSAGE_PREVIEW = '._1htf';
const MESSAGE_ID = '._5l-3._1ht5';
const MESSAGE_SENDER = '._1ht6';
const MESSAGE_SENDER_PICTURE = '._55lt img';
const MESSAGE_UNREAD = '_1ht3';
const MESSAGE_SELECTED = '_1ht2';
const EMOJI = '_1ift';
const MUTED = '_569x';
const SELECTED_CONVERSATION = '._1ht2';
const ACTIVATE_CONVERSATION = 'a._1ht5';
const SETTINGS_BUTTON = '._1enh ._36ic ._4kzu a';
const SETTINGS_LINK = '._54ni.__MenuItem:first-child';
const MESSAGE_LIST_INBOX_LINK = '._1enh ._36ic ._30yy';
const MESSAGE_LIST_ACTIVE_CONTACTS_LINK = '._54ni.__MenuItem:nth-child(3)';
const MESSAGE_LIST_MESSAGE_REQUESTS_LINK = '._54ni.__MenuItem:nth-child(4)';
const MESSAGE_LIST_ARCHIVED_THREADS_LINK = '._54ni.__MenuItem:nth-child(5)';

ipcRenderer.on(constants.NEW_CONVERSATION, () => {
	document.querySelector(NEW_MESSAGE_BUTTON).click();
});

ipcRenderer.on(constants.SHOW_MESSAGE_LIST_INBOX, () => {
	if (!isShowingInbox) {
		document.querySelector(MESSAGE_LIST_INBOX_LINK).click();
		resetSettingsOptions();
	}
	isShowingInbox = true;
});

ipcRenderer.on(constants.SHOW_MESSAGE_LIST_ACTIVE_CONTACTS, () => {
	openMessageList(MESSAGE_LIST_ACTIVE_CONTACTS_LINK);
});

ipcRenderer.on(constants.SHOW_MESSAGE_LIST_MESSAGE_REQUESTS, () => {
	openMessageList(MESSAGE_LIST_MESSAGE_REQUESTS_LINK);
});

ipcRenderer.on(constants.SHOW_MESSAGE_LIST_ARCHIVED_THREADS, () => {
	openMessageList(MESSAGE_LIST_ARCHIVED_THREADS_LINK);
});

function openMessageList(messageListLink) {
	if (!isShowingInbox) {
		document.querySelector(MESSAGE_LIST_INBOX_LINK).click();
		resetSettingsOptions();
	}
	document.querySelector(messageListLink).click();
	isShowingInbox = false;
}

ipcRenderer.on(constants.SHOW_SETTINGS, () => {
	document.querySelector(SETTINGS_LINK).click();
});

ipcRenderer.on(constants.NEXT_CONVERSATION, () => {
	let nextConversation = document.querySelector(SELECTED_CONVERSATION).nextSibling;
	if (nextConversation) {
		nextConversation.querySelector(ACTIVATE_CONVERSATION).click();
	}
});

ipcRenderer.on(constants.PREV_CONVERSATION, () => {
	let nextConversation = document.querySelector(SELECTED_CONVERSATION).previousSibling;
	if (nextConversation) {
		nextConversation.querySelector(ACTIVATE_CONVERSATION).click();
	}
});

ipcRenderer.on(constants.JUMP_TO_CONVERATION, (event, id) => {
	let nextConversation = document.querySelector(`[id='${id}'] a`);
	if (nextConversation) {
		nextConversation.click();
	}
});


let lastDockCount = null;
document.addEventListener('DOMContentLoaded', () => {
	// dock count
	document.querySelector(UNREAD_MESSAGE_COUNT).addEventListener('DOMSubtreeModified', e => {
		const currentDockCount = parseInt(e.target.textContent) || 0;
		ipcRenderer.sendToHost(constants.DOCK_COUNT, currentDockCount);
		if (lastDockCount === null) {
			lastDockCount = currentDockCount;
		}
		if (lastDockCount === currentDockCount) {
			return;
		}
		processNotifications();
	});

	// load settings menu once, so it is inserted in the DOM
	setTimeout(
		() => {
			resetSettingsOptions();
		},
		1000
	);
});

function resetSettingsOptions() {
	const button = document.querySelector(SETTINGS_BUTTON);
	if (button) {
		button.click();
		button.click();  // clicking again to hide
	}
}

function messageWithEmojis(node) {
	let message = '';
	if (node.querySelector('span')) {
		node = node.querySelector('span');
	}
	node.childNodes.forEach(n => {
		if (n.nodeType === 3) {
			message += n.textContent;
		} else if (
			n.nodeName === 'SPAN'
			&& n.querySelector('img')
			&& n.querySelector('img').getAttribute('alt') === '<U+F0000>'
		) {
			// facebook thumb up
			message += '👍';
		} else if (n.nodeName === 'IMG' && n.classList.contains(EMOJI)) {
			const alt = n.getAttribute('alt');
			message += alt;
		}
	});
	return message;
}

function processNotifications() {
	// send notifications
	if (document.querySelector(MESSAGE_LIST)) {
		if (!latestMessages) {
			// init latestMessages map
			latestMessages = new Map();
			document.querySelector(MESSAGE_LIST).childNodes.forEach(message => {
				const m = message.querySelector(MESSAGE_ID);
				if (m) {
					latestMessages.set(
						m.getAttribute('id'),
						messageWithEmojis(message.querySelector(MESSAGE_PREVIEW))
					);
				}
			});
		} else {
			document.querySelector(MESSAGE_LIST).childNodes.forEach(message => {
				const id = message.querySelector(MESSAGE_ID).getAttribute('id');
				const messageElement = message.querySelector(MESSAGE_PREVIEW);
				const messageBody = messageWithEmojis(messageElement);

				if (latestMessages.get(id) !== messageBody) {
					const name = message.querySelector(MESSAGE_SENDER).textContent;
					const image = message.querySelector(MESSAGE_SENDER_PICTURE).getAttribute('src');

					// check if it's a message from myself
					const isMessageFromSelf = messageElement.childNodes[0] &&
						messageElement.childNodes[0].nodeName === '#text'
					;

					const muted = message.classList.contains(MUTED);

					if (!isMessageFromSelf && !muted) {
						let notification = new Notification(name, {
							body: messageBody,
							icon: image,
							data: id,
							silent: true,
						});
						notification.onclick = e => {
							document.querySelector(`[id="${e.target.data}"] ${ACTIVATE_CONVERSATION}`).click();
						};
					}

					latestMessages.set(id, messageBody);
				}
			});
		}
	}

	ipcRenderer.sendToHost(constants.TOUCH_BAR, []);

	// update TouchBar
	if (document.querySelector(MESSAGE_LIST)) {
		const unreadLinks = [];
		const readLinks = [];

		document.querySelector(MESSAGE_LIST).childNodes.forEach(message => {
			const item = {
				name: message.querySelector(MESSAGE_SENDER).textContent,
				unread: message.classList.contains(MESSAGE_UNREAD),
				active: message.classList.contains(MESSAGE_SELECTED),
				id: message.childNodes[0].getAttribute('id'),
			};
			if (item.unread) {
				unreadLinks.push(item);
			} else {
				readLinks.push(item);
			}
		});

		ipcRenderer.sendToHost(constants.TOUCH_BAR, JSON.stringify(unreadLinks.concat(readLinks).slice(0, 5)));
	}
}
