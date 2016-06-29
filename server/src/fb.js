// Facebook selectors
var SETTINGS_BUTTON = '._30yy._2fug._p',
    NEW_MESSAGE_BUTTON = '._36ic._5l-3 > a._30yy',
    INFORMATION_BUTTON = '._fl3._30yy';

var UPLOAD_BUTTON = '._m._4q60._3rzn._6a',
    UPLOAD_FORM = '._4rv4 form';

var TEXT_BOX = '._5rpu',
    SEARCH_BOX = '._58al';

var TITLE_BAR = '._5743',
    LAST_ACTIVE = '._2v6o';

var CURRENT_CONVERSATION_NAME = TITLE_BAR + ' span',
    CONVERSATION_LIST = '._2xhi ul',
    SELECTED_CONVERSATION = '._1ht2';

var _MENU_ITEMS = '._54nq._2i-c._558b._2n_z li',
    SETTINGS_MENU_ITEM = _MENU_ITEMS + ':first-child',
    LOGOUT_MENU_ITEM = _MENU_ITEMS + ':last-child';

var UNREAD_CONVERSATION = '._1ht3',
    UNREAD_MESSAGE_NAME = UNREAD_CONVERSATION + ' ._1ht6',
    UNREAD_MESSAGE_TEXT = UNREAD_CONVERSATION + ' ._1htf',
    UNREAD_MESSAGE_ROW = UNREAD_CONVERSATION + '._1ht1 div',
    UNREAD_MESSAGE_PICTURE = '._55lt > .img';

var EMOTICONS = '._1ift',
    MUTED = '_569x';

var _localeKeyword = Array.prototype.filter.call(document.body.classList, function(e) {
	return e.startsWith("Locale");
})[0];

// Resistant if Facebook stops exposing locale as a class
var LOCALE = _localeKeyword ? _localeKeyword.replace("Locale_", "") : "";

var YOU_KEYWORDS = {"default": "You: ", "tr_TR": "Sen: "};
var YOU = YOU_KEYWORDS.hasOwnProperty(LOCALE) ? YOU_KEYWORDS[LOCALE] : YOU_KEYWORDS["default"];

function CONVERSATION_LINK(user_id) { return '[data-reactid="' + user_id + '"] a' }
function ID(id) { return '[id="' + id + '"]' }

var lastNotification,
    lastNotificationTime,
    dockCounter = "",
    ignoreNotification = false;

(function(f,b){if(!b.__SV){var a,e,i,g;window.mixpanel=b;b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");
for(g=0;g<i.length;g++)f(c,i[g]);b._i.push([a,e,d])};b.__SV=1.2;a=f.createElement("script");a.type="text/javascript";a.async=!0;a.src="//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js";e=f.getElementsByTagName("script")[0];e.parentNode.insertBefore(a,e)}})(document,window.mixpanel||[]);
mixpanel.init("2245181dbc803998dedc5b07d840e672");

csssetup = function() {
	head = document.head || document.getElementsByTagName('head')[0];
	style = document.createElement('style');
	style.type = 'text/css';
	if (style.styleSheet) {
		style.styleSheet.cssText = css;
	} else {
		style.appendChild(document.createTextNode(css));
	}
	head.appendChild(style);
};

function init() {
	csssetup();

	setInterval(function() {
		updateTitle();
		dockCount();

		var uploadButton = document.querySelector(UPLOAD_BUTTON);
		if (uploadButton && uploadButton.onclick==null) {
			uploadButton.onclick = function(e) {
				e.preventDefault();
				e.stopPropagation();
				uploadInfo();
			}
		}
	}, 200);

	setTimeout(function() {
		//render settings menu
		document.querySelector(SETTINGS_BUTTON).click();
		mixpanel.track("loaded");
		window.dispatchEvent(new Event('resize'));
	}, 3000);


	document.body.onkeypress = function(e) {
		// If no inputs are focused, or we're at the start of the message input (to prevent system beep), focus the message input and trigger the keypress.
		if ((!document.querySelector(':focus') || (document.querySelector(TEXT_BOX + ':focus') && window.getSelection().baseOffset === 0)) && !e.metaKey && !e.ctrlKey) {
			var char = event.which || event.keyCode;

			// Focus the input at the end of any current text.
			var el = document.querySelector(TEXT_BOX),
			    range = document.createRange(),
			    sel = window.getSelection();
			range.setStart(el, 1);
			range.collapse(true);
			sel.removeAllRanges();
			sel.addRange(range);

			// Trigger the captured key press.
			var textEvent = document.createEvent('TextEvent');
			textEvent.initTextEvent('textInput', true, true, null, String.fromCharCode(char), 9, "en-US");
			el.dispatchEvent(textEvent);

			return false;
		}
	};

	document.querySelector(TITLE_BAR).addEventListener("DOMSubtreeModified", function() {
		updateTitle();
	});
}

function uploadInfo() {
	window.webkit.messageHandlers.notification.postMessage({type: 'CHOOSE_IMAGE'});
}

function updateTitle() {
	var a = document.querySelector(LAST_ACTIVE) ? document.querySelector(LAST_ACTIVE).textContent : "";
	window.webkit.messageHandlers.notification.postMessage({type: 'SET_TITLE', title: document.querySelector(CURRENT_CONVERSATION_NAME).textContent, activity: a});
}

function newConversation() {
	document.querySelector(NEW_MESSAGE_BUTTON).click();
}

function gotoConversation(tag) {
	if (tag==1) {
		document.querySelector(SELECTED_CONVERSATION).nextElementSibling.querySelector('a').click();
	} else {
		document.querySelector(SELECTED_CONVERSATION).previousElementSibling.querySelector('a').click();
	}
}

function gotoConversationAtIndex(index) {
	document.querySelector(CONVERSATION_LIST + 'li:nth-child(' + index + ') a').click();
}

function reactivation(userid) {
	if (userid) {
		document.querySelector(CONVERSATION_LINK(user_id)).click();
	} else if (new Date().getTime() < lastNotificationTime + 1000*60) {
		document.querySelector(UNREAD_CONVERSATION + ' a').click();
	}
}

function logout() {
	document.querySelector(LOGOUT_MENU_ITEM).click();
}

function info() {
	document.querySelector(INFORMATION_BUTTON).click();
}

function preferences() {
	document.querySelector(SETTINGS_MENU_ITEM).click();
}

function search() {
	document.querySelector(SEARCH_BOX).focus();
}

function dockCount() {
	var c = document.querySelectorAll(UNREAD_CONVERSATION).length;
	if (c != dockCounter) {
		window.webkit.messageHandlers.notification.postMessage({type: 'DOCK_COUNT', content: String(c)});
		dockCounter = c;
	}

	if (c > 0) {
		var text = document.querySelector(UNREAD_MESSAGE_TEXT);
		if (text) {
			text = text.textContent;

			/* Sometimes messages are bold when *you* have sent a message and the conversation is
			unread. This stops that, all those begin with "You: " in a separate <span>, or a
			language-specific varient */
			var messageHTML = document.querySelector(UNREAD_MESSAGE_TEXT).innerHTML;
			if (messageHTML.indexOf("<span>" + YOU + "</span>") != -1) {
				return
			}

			var subtitle = document.querySelector(UNREAD_MESSAGE_NAME).textContent;
			if (lastNotification != subtitle+text) {
				var el = document.querySelector(UNREAD_MESSAGE_TEXT);

				[].forEach.call(document.querySelectorAll(EMOTICONS), function(a) {
					a.textContent = "";
				});

				var emojiMessage = document.querySelector(UNREAD_MESSAGE_TEXT + ' ' + EMOTICONS);
				if (emojiMessage) {
					emojiMessage.textContent = findSurrogatePair(parseInt(document.querySelector(UNREAD_MESSAGE_TEXT + ' ' + EMOTICONS).getAttribute('src').split('/').reverse()[0].split('.')[0], 16)).map(function(a) {return String.fromCharCode(parseInt(a,16));}).join('');
				}
				text = document.querySelector(UNREAD_MESSAGE_TEXT).textContent;

				var id = document.querySelector(UNREAD_MESSAGE_ROW).getAttribute('id'),
				    pictureUrl = document.querySelector(UNREAD_MESSAGE_ROW).querySelector(UNREAD_MESSAGE_PICTURE);
				pictureUrl = pictureUrl ? pictureUrl.getAttribute('src') : "";

				if (ignoreNotification || document.querySelector(ID(id)).parentElement.classList.contains(MUTED)) {
					ignoreNotification = false;
				} else {
					window.webkit.messageHandlers.notification.postMessage({type: 'NOTIFICATION', title: subtitle, text: text, id: id, pictureUrl: pictureUrl});
					window.webkit.messageHandlers.notification.postMessage({type: 'DOCK_COUNT', content: String(c)});
				}

				lastNotification = subtitle + text;
				lastNotificationTime = new Date().getTime();
			}
		}
	}
}

function findSurrogatePair(point) {
	// assumes point > 0xffff
	var offset = point - 0x10000,
		lead = 0xd800 + (offset >> 10),
		trail = 0xdc00 + (offset & 0x3ff);
	return [lead.toString(16), trail.toString(16)];
}

function replyToNotification(userid, answer) {
	document.querySelector(ID(userid) + ' a').click();
	setTimeout(function() {
		var textEvent = document.createEvent('TextEvent');
		textEvent.initTextEvent('textInput', true, true, null, answer, 9, "en-US");
		document.querySelector(TEXT_BOX).dispatchEvent(textEvent);
		ignoreNotification = true;
		__triggerKeyboardEvent(document.querySelector(TEXT_BOX),13,true);
	}, 50);
}

function getValueForFirstObjectKey(object) {
	var keys = Object.keys(object);
	return (keys.length > 0) ? object[keys[0]] : null;
}

// Handle pasted image data forwarded from the wrapper app.
function pasteImage(base64Data) {
	var blob = b64toBlob(base64Data, 'image/png'),
	    uploader = getValueForFirstObjectKey(getValueForFirstObjectKey(__REACT_DEVTOOLS_GLOBAL_HOOK__._renderers).ComponentTree.getClosestInstanceFromNode(document.querySelector(UPLOAD_FORM).parentElement)._renderedChildren);
	uploader._instance.uploadFiles([blob]);
}

// Convert base64 encoded data to a Blob.
function b64toBlob(b64Data, contentType, sliceSize) {
	contentType = contentType || '';
	sliceSize = sliceSize || 512;

	var byteCharacters = atob(b64Data),
	    byteArrays = [];

	for (var offset = 0; offset < byteCharacters.length; offset += sliceSize) {
		var slice = byteCharacters.slice(offset, offset + sliceSize);

		var byteNumbers = new Array(slice.length);
		for (var i = 0; i < slice.length; i++) {
			byteNumbers[i] = slice.charCodeAt(i);
		}

		var byteArray = new Uint8Array(byteNumbers);

		byteArrays.push(byteArray);
	}

	var blob = new Blob(byteArrays, {type: contentType});
	return blob;
}

function __triggerKeyboardEvent(el, keyCode, meta) {
	var eventObj = document.createEventObject ?
		document.createEventObject() : document.createEvent("Events");

	if (eventObj.initEvent) {
		eventObj.initEvent("keydown", true, true);
	}

	eventObj.keyCode = eventObj.which = keyCode;
	if (meta) {
		eventObj.metaKey = true;
	}

	el.dispatchEvent ? el.dispatchEvent(eventObj) : el.fireEvent("onkeydown", eventObj);
}
