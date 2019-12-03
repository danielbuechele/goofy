'use strict';

const { ipcRenderer } = require('electron');

const constants = require('./helpers/constants');
const { whenUIChromeLoaded, isPreviousMessengerVersion } = require('./helpers/common');

const NEW_MESSAGE_BUTTON = '._30yy._6-xp._6-xq';
const NEW_MESSAGE_BUTTON_PREV = '._1enh ._36ic ._30yy._2oc8';
const SELECTED_CONVERSATION = '._1ht2';
const ACTIVATE_CONVERSATION = 'a._1ht5';

// Settings dropdown
const SETTINGS_BUTTON = '._1enh._7q1s ._30yy._6ymd._2agf._4o_4._p';  // The "cog" button which shows the Settings dropdown
const SETTINGS_BUTTON_PREV = '._1enh ._36ic ._4kzu a';
const SETTINGS_LINK = '._54ni.__MenuItem:first-child';  // The "Settings" link in the Settings dropdown

// Following are Message List navigation options in the Settings dropdown
const MESSAGE_LIST_INBOX_LINK = '._1enh._7q1s ._30yy._6-xf._6-xg';
const MESSAGE_LIST_INBOX_LINK_PREV = '._1enh ._36ic ._30yy';
const MESSAGE_LIST_ACTIVE_CONTACTS_LINK  = '._54ni.__MenuItem:nth-child(3)';
const MESSAGE_LIST_MESSAGE_REQUESTS_LINK = '._54ni.__MenuItem:nth-child(4)';
const MESSAGE_LIST_ARCHIVED_THREADS_LINK = '._54ni.__MenuItem:nth-child(5)';

// Conversation dropdown
const CONVERSATION_DROPDOWN_LINK_SUFFIX = '._5blh';
const CONVERSATION_DROPDOWN = '._54nf';
const CONVERSATION_DROPDOWN_ITEM_LINK_PREFIX = '._54ni.__MenuItem';

const MUTE_CONVERSATION_LINK_INDEX                 = 1;
const ARCHIVE_CONVERSATION_LINK_INDEX              = 3;
const DELETE_CONVERSATION_LINK_INDEX               = 4;
const MARK_CONVERSATION_UNREAD_LINK_INDEX          = 6;
const MARK_CONVERSATION_SPAM_LINK_INDEX            = 7;
const REPORT_CONVERSATION_SPAM_OR_ABUSE_LINK_INDEX = 8;

const MUTE_GROUP_CONVERSATION_LINK_INDEX                 = 1;
const ARCHIVE_GROUP_CONVERSATION_LINK_INDEX              = 4;
const DELETE_GROUP_CONVERSATION_LINK_INDEX               = 5;
const MARK_GROUP_CONVERSATION_UNREAD_LINK_INDEX          = 7;
const MARK_GROUP_CONVERSATION_SPAM_LINK_INDEX            = 8;
const REPORT_GROUP_CONVERSATION_SPAM_OR_ABUSE_LINK_INDEX = 9;

// Conversation actions
const LIKE_CONVERSATION_LINK = '._5j_u._30yy._4rv9._6ymq._7kpj';
const LIKE_CONVERSATION_LINK_PREV = '._4rv9._30yy._39bl';

let hasResetInitialSettingsDropdown = false;

function bindKeyboardShortcuts() {
	whenUIChromeLoaded(() => {
		if (hasResetInitialSettingsDropdown) {
			return;
		}
		resetSettingsDropdown();
		hasResetInitialSettingsDropdown = true;
	});
	
	// Main menu
	// - Show Settings
	ipcRenderer.on(constants.SHOW_MESSENGER_SETTINGS, () => {
		document.querySelector(SETTINGS_LINK).click();
	});

	// File menu
	// - New Conversation
	ipcRenderer.on(constants.NEW_CONVERSATION, () => {
		document.querySelector(isPreviousMessengerVersion() ? NEW_MESSAGE_BUTTON_PREV : NEW_MESSAGE_BUTTON).click();
		ipcRenderer.send(constants.OPEN_MESSENGER);
	});
	
	// View menu
	// - Inbox
	ipcRenderer.on(constants.SHOW_MESSAGE_LIST_INBOX, () => {
		resetMessageListToInbox();
		ipcRenderer.send(constants.OPEN_MESSENGER);
	});
	
	// - Active contacts
	ipcRenderer.on(constants.SHOW_MESSAGE_LIST_ACTIVE_CONTACTS, () => {
		openMessageList(MESSAGE_LIST_ACTIVE_CONTACTS_LINK);
		ipcRenderer.send(constants.OPEN_MESSENGER);
	});
	
	// - Message requests
	ipcRenderer.on(constants.SHOW_MESSAGE_LIST_MESSAGE_REQUESTS, () => {
		openMessageList(MESSAGE_LIST_MESSAGE_REQUESTS_LINK);
		ipcRenderer.send(constants.OPEN_MESSENGER);
	});
	
	// - Archived threads
	ipcRenderer.on(constants.SHOW_MESSAGE_LIST_ARCHIVED_THREADS, () => {
		openMessageList(MESSAGE_LIST_ARCHIVED_THREADS_LINK);
		ipcRenderer.send(constants.OPEN_MESSENGER);
	});
	
	// Conversation menu
	// - Mute conversation
	ipcRenderer.on(constants.MUTE_CONVERSATION, () => {
		conversationAction(MUTE_CONVERSATION_LINK_INDEX, MUTE_GROUP_CONVERSATION_LINK_INDEX);
	});
	
	// - Archive conversation
	ipcRenderer.on(constants.ARCHIVE_CONVERSATION, () => {
		conversationAction(ARCHIVE_CONVERSATION_LINK_INDEX, ARCHIVE_GROUP_CONVERSATION_LINK_INDEX);
	});

	// - Delete conversation
	ipcRenderer.on(constants.DELETE_CONVERSATION, () => {
		conversationAction(DELETE_CONVERSATION_LINK_INDEX, DELETE_GROUP_CONVERSATION_LINK_INDEX);
	});

	// - Mark read / unread conversation
	ipcRenderer.on(constants.MARK_CONVERSATION_UNREAD, () => {
		conversationAction(MARK_CONVERSATION_UNREAD_LINK_INDEX, MARK_GROUP_CONVERSATION_UNREAD_LINK_INDEX);
	});

	// - Mark spam conversation
	ipcRenderer.on(constants.MARK_CONVERSATION_SPAM, () => {
		conversationAction(MARK_CONVERSATION_SPAM_LINK_INDEX, MARK_GROUP_CONVERSATION_SPAM_LINK_INDEX);
	});

	// - Report conversation
	ipcRenderer.on(constants.REPORT_CONVERSATION_SPAM_OR_ABUSE, () => {
		conversationAction(REPORT_CONVERSATION_SPAM_OR_ABUSE_LINK_INDEX, 
			REPORT_GROUP_CONVERSATION_SPAM_OR_ABUSE_LINK_INDEX);
	});
	
	// Window menu
	// - Select next Conversation
	ipcRenderer.on(constants.NEXT_CONVERSATION, () => {
		const nextConversation = document.querySelector(SELECTED_CONVERSATION).nextSibling;
		if (nextConversation) {
			nextConversation.querySelector(ACTIVATE_CONVERSATION).click();
		}
	});
	
	// - Select previous Conversation
	ipcRenderer.on(constants.PREV_CONVERSATION, () => {
		const nextConversation = document.querySelector(SELECTED_CONVERSATION).previousSibling;
		if (nextConversation) {
			nextConversation.querySelector(ACTIVATE_CONVERSATION).click();
		}
	});

	// Touchbar
	// - Like conversation
	ipcRenderer.on(constants.LIKE_CONVERSATION, () => {
		const like = document.querySelector(isPreviousMessengerVersion() ? LIKE_CONVERSATION_LINK_PREV : LIKE_CONVERSATION_LINK);
		if (like) {
			const mouseDown = document.createEvent('MouseEvents');
			mouseDown.initEvent('mousedown', true, true);
			like.dispatchEvent(mouseDown);

			const mouseUp = document.createEvent('MouseEvents');
			mouseUp.initEvent('mouseup', true, true);
			like.dispatchEvent(mouseUp);
		}
	});
}
	
function openMessageList(messageListLink) {
	resetMessageListToInbox();
	document.querySelector(messageListLink).click();
}

function conversationAction(index, groupIndex) {
	const conversationMenuLink = document.querySelector(`${SELECTED_CONVERSATION} ${CONVERSATION_DROPDOWN_LINK_SUFFIX}`);
	if (!conversationMenuLink) {
		return;
	}
	conversationMenuLink.click();

	// There could be multiple menus displaying - pick the correct one
	document.querySelectorAll(CONVERSATION_DROPDOWN).forEach(menu => {
		const menuItemStrings = Array.from(menu.querySelectorAll(`${CONVERSATION_DROPDOWN_ITEM_LINK_PREFIX}`))
			.map(elem => { return elem.textContent; });

		const foundConversationMenu = menuItemStrings.includes('Mute') || menuItemStrings.includes('Unmute');
		if (!foundConversationMenu) {
			return;
		}

		const rootMenuElem = menu.parentElement.parentElement.parentElement;
		if (rootMenuElem) {
			// Hide menu before displaying. Note, don't need to un-hide 
			// after clicked as menu disappears after clicking
			rootMenuElem.style.visibility = 'hidden';
		}

		const isGroupConversation = menuItemStrings.includes('Leave Group');
		if (isGroupConversation) {
			const elem = menu.querySelector(`${CONVERSATION_DROPDOWN_ITEM_LINK_PREFIX}:nth-child(${groupIndex})`);
			if (elem) {
				elem.click();
			}
			return;
		}

		const elem = menu.querySelector(`${CONVERSATION_DROPDOWN_ITEM_LINK_PREFIX}:nth-child(${index})`);
		if (elem) {
			elem.click();
		}
	});
}

function resetMessageListToInbox() {
	const activeContactsLink = document.querySelector(MESSAGE_LIST_ACTIVE_CONTACTS_LINK);
	if (activeContactsLink) {
		// If the Active Contacts link visible, Inbox is already showing
		return;
	}

	const messageListInbox = document.querySelector(isPreviousMessengerVersion() ? MESSAGE_LIST_INBOX_LINK_PREV : MESSAGE_LIST_INBOX_LINK);
	if (messageListInbox) {
		messageListInbox.click();
	}

	resetSettingsDropdown();
}

/**
 * Opens and closes the Settings dropdown so it's inserted into the DOM (so we 
 * can get those link elements and activate them)
 */
function resetSettingsDropdown() {
	const button = document.querySelector(isPreviousMessengerVersion() ? SETTINGS_BUTTON_PREV : SETTINGS_BUTTON);
	if (button) {
		button.click();
		button.click();  // clicking again to hide
	}
}

module.exports = bindKeyboardShortcuts;
