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
    UNREAD_MESSAGE_PICTURE = '._1ht3 ._55lt > .img';

var EMOTICONS = '.emoticon_text',
    ALL_EMOJI = '.emoticon, ._1az',
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

	convertEmoji();

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

				text = document.querySelector(UNREAD_MESSAGE_TEXT).textContent;

				var id = document.querySelector(UNREAD_MESSAGE_ROW).getAttribute('id'),
				    pictureUrl = document.querySelector(UNREAD_MESSAGE_PICTURE);
				pictureUrl = pictureUrl ? pictureUrl.getAttribute('src') : "";

				if (ignoreNotification || document.querySelector(ID(id)).parentElement.classList.toString().indexOf(MUTED) > -1) {
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

function convertEmoji() {
	var emoticon = document.querySelectorAll(ALL_EMOJI);
	[].forEach.call(emoticon, function(e) {
		e.classList.toString().split(" ").forEach(function(c) {
			if (EMOJI_TABLE[c]) {
				e.parentNode.replaceChild(document.createTextNode(EMOJI_TABLE[c]), e);
			}
		});
	});
}

var EMOJI_TABLE = {
	"emoticon_smile": "😊",
	"emoticon_frown": "😞",
	"emoticon_tongue": "😛",
	"emoticon_grin": "😀",
	"emoticon_gasp": "😦",
	"emoticon_wink": "😉",
	"emoticon_pacman": ":v",
	"emoticon_grumpy": "😠",
	"emoticon_unsure": "😕",
	"emoticon_cry": "😢",
	"emoticon_kiki": "😊",
	"emoticon_glasses": "8)",
	"emoticon_sunglasses": "😎",
	"emoticon_heart": "❤️",
	"emoticon_devil": "😈",
	"emoticon_angel": "😇",
	"emoticon_squint": "😑",
	"emoticon_confused": "😕",
	"emoticon_confused_rev": "😕",
	"emoticon_upset": "😠",
	"emoticon_colonthree": ":3",
	"emoticon_like": "👍",
	"emoticon_kiss": "😘",
	"emoticon_shark": "(^^^)",
	"emoticon_robot": "🤖",
	"emoticon_penguin": "🐧",
	"emoticon_poop": "💩",
	"emoticon_putnam": ":putnam:",
	"_1q3y": "😊",
	"_2c0": "🌂",
	"_2c1": "🌊",
	"_2c2": "🌙",
	"_2c3": "🌟",
	"_2c4": "🌱",
	"_2c5": "🌴",
	"_2c6": "🌵",
	"_2c7": "🌷",
	"_2c8": "🌸",
	"_2c9": "🌹",
	"_2ca": "🌺",
	"_2cb": "🌻",
	"_2cc": "🌾",
	"_2cd": "🍀",
	"_2ce": "🍁",
	"_2cf": "🍂",
	"_2cg": "🍃",
	"_2ch": "🍊",
	"_2ci": "🍎",
	"_2cj": "🍓",
	"_2ck": "🍔",
	"_2cl": "🍸",
	"_2cm": "🍺",
	"_2cn": "🎁",
	"_2co": "🎃",
	"_2cp": "🎄",
	"_2cq": "🎅",
	"_2cr": "🎈",
	"_2cs": "🎉",
	"_2ct": "🎍",
	"_2cu": "🎎",
	"_2cv": "🎏",
	"_2cw": "🎐",
	"_2cx": "🎓",
	"_2cy": "🎵",
	"_2cz": "🎶",
	"_2c-": "🎼",
	"_2c_": "🐍",
	"_2d0": "🐎",
	"_2d1": "🐑",
	"_2d2": "🐒",
	"_2d3": "🐔",
	"_2d4": "🐗",
	"_2d5": "🐘",
	"_2d6": "🐙",
	"_2d7": "🐚",
	"_2d8": "🐛",
	"_2d9": "🐟",
	"_2da": "🐠",
	"_2db": "🐡",
	"_2dc": "🐥",
	"_2dd": "🐦",
	"_2de": "🐧",
	"_2df": "🐨",
	"_2dg": "🐩",
	"_2dh": "🐫",
	"_2di": "🐬",
	"_2dj": "🐭",
	"_2dk": "🐮",
	"_2dl": "🐯",
	"_2dm": "🐰",
	"_2dn": "🐱",
	"_2do": "🐳",
	"_2dp": "🐴",
	"_2dq": "🐵",
	"_2dr": "🐷",
	"_2ds": "🐸",
	"_2dt": "🐹",
	"_2du": "🐺",
	"_2dv": "🐻",
	"_2dw": "🐾",
	"_2dx": "👀",
	"_2dy": "👂",
	"_2dz": "👃",
	"_2d-": "👄",
	"_2d_": "👅",
	"_2e0": "👆",
	"_2e1": "👇",
	"_2e2": "👈",
	"_2e3": "👉",
	"_2e4": "👊",
	"_2e5": "👋",
	"_2e6": "👌",
	"_2e7": "👍",
	"_2e8": "👎",
	"_2e9": "👏",
	"_2ea": "👐",
	"_2eb": "👦",
	"_2ec": "👧",
	"_2ed": "👨",
	"_2ee": "👩",
	"_2ef": "👫",
	"_2eg": "👮",
	"_2eh": "👯",
	"_2ei": "👱",
	"_2ej": "👲",
	"_2ek": "👳",
	"_2el": "👴",
	"_2em": "👵",
	"_2en": "👶",
	"_2eo": "👷",
	"_2ep": "👸",
	"_2eq": "👻",
	"_2er": "👼",
	"_2es": "👽",
	"_2et": "👾",
	"_2eu": "👿",
	"_2ev": "💀",
	"_2ew": "💂",
	"_2ex": "💃",
	"_2ey": "💅",
	"_2ez": "💋",
	"_2e-": "💏",
	"_2e_": "💐",
	"_2f0": "💑",
	"_2f1": "💓",
	"_2f2": "💔",
	"_2f3": "💖",
	"_2f4": "💗",
	"_2f5": "💘",
	"_2f6": "💙",
	"_2f7": "💚",
	"_2f8": "💛",
	"_2f9": "💜",
	"_2fa": "💝",
	"_2fb": "💢",
	"_2fc": "💤",
	"_2fd": "💦",
	"_2fe": "💨",
	"_2ff": "💩",
	"_2fg": "💪",
	"_2fh": "💻",
	"_2fi": "💽",
	"_2fj": "💾",
	"_2fk": "💿",
	"_2fl": "📀",
	"_2fm": "📞",
	"_2fn": "📠",
	"_2fo": "📱",
	"_2fp": "📲",
	"_2fq": "📺",
	"_2fr": "🔔",
	"_2fs": "😁",
	"_2ft": "😂",
	"_2fu": "😃",
	"_2fv": "😄",
	"_2fw": "😆",
	"_2fx": "😉",
	"_2fy": "😋",
	"_2fz": "😌",
	"_2f-": "😍",
	"_2f_": "😏",
	"_2g0": "😒",
	"_2g1": "😓",
	"_2g2": "😔",
	"_2g3": "😖",
	"_2g4": "😘",
	"_2g5": "😚",
	"_2g6": "😜",
	"_2g7": "😝",
	"_2g8": "😞",
	"_2g9": "😠",
	"_2ga": "😡",
	"_2gb": "😢",
	"_2gc": "😣",
	"_2gd": "😤",
	"_2ge": "😥",
	"_2gf": "😨",
	"_2gg": "😩",
	"_2gh": "😪",
	"_2gi": "😫",
	"_2gj": "😭",
	"_2gk": "😰",
	"_2gl": "😱",
	"_2gm": "😲",
	"_2gn": "😳",
	"_2go": "😵",
	"_2gp": "😷",
	"_2gq": "😸",
	"_2gr": "😹",
	"_2gs": "😺",
	"_2gt": "😻",
	"_2gu": "😼",
	"_2gv": "😽",
	"_2gw": "😿",
	"_2gx": "🙀",
	"_2gy": "🙋",
	"_2gz": "🙌",
	"_2g-": "🙍",
	"_2g_": "🙏",
	"_2h0": "☝️",
	"_2h1": "☺️",
	"_2h2": "⚡️",
	"_2h3": "⛄",
	"_2h4": "✊",
	"_2h5": "✋",
	"_2h6": "✌️",
	"_2h7": "☀️",
	"_2h8": "☁️",
	"_2h9": "☔️",
	"_2ha": "☕️",
	"_2hb": "✨",
	"_2hc": "❤️"
};
