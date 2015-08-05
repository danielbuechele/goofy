var lastNotification;
var lastNotificationTime;
var dockCounter = "";
var ignoreNotification = false;

(function(f,b){if(!b.__SV){var a,e,i,g;window.mixpanel=b;b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");
for(g=0;g<i.length;g++)f(c,i[g]);b._i.push([a,e,d])};b.__SV=1.2;a=f.createElement("script");a.type="text/javascript";a.async=!0;a.src="//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js";e=f.getElementsByTagName("script")[0];e.parentNode.insertBefore(a,e)}})(document,window.mixpanel||[]);
mixpanel.init("2245181dbc803998dedc5b07d840e672");

// Get React's runtime using the dev tool hook.
Object.defineProperty(window, '__REACT_DEVTOOLS_GLOBAL_HOOK__', {
	value: {
		inject: function(runtime) {this._reactRuntime = runtime; },
		getSelectedInstance: null,
		Overlay: null
	}
});

var emoticonMapping = {
	"emoticon_smile"		:"😃",
	"emoticon_frown"		:"😦",
	"emoticon_poop"			:"💩",
	"emoticon_putnam"		:":putnam:",
	"emoticon_tongue"		:"😛",
	"emoticon_grin"			:"😀",
	"emoticon_gasp"			:"😦",
	"emoticon_wink"			:"😉",
	"emoticon_glasses"		:"8-)",
	"emoticon_sunglasses"	:"😎",
	"emoticon_grumpy"		:">:(",
	"emoticon_unsure"		:":/",
	"emoticon_cry"			:"😢",
	"emoticon_devil"		:"😈",
	"emoticon_angel"		:"😇",
	"emoticon_kiss"			:"😘",
	"emoticon_heart"		:"❤️",
	"emoticon_kiki"			:"😊",
	"emoticon_squint"		:"😑",
	"emoticon_confused"		:"😕",
	"emoticon_confused_rev"	:"😕",
	"emoticon_upset"		:">:o",
	"emoticon_pacman"		:":v",
	"emoticon_robot"		:":|]",
	"emoticon_colonthree"	:":3",
	"emoticon_penguin"		:"🐧",
	"emoticon_shark"		:"(^^^)",
	"emoticon_like"			:"👍"
};

csssetup = function() {
	head = document.head || document.getElementsByTagName( 'head' )[ 0 ];
	style = document.createElement( 'style' );
	style.type = 'text/css';
	if ( style.styleSheet ) {
			style.styleSheet.cssText = css;
	} else {
			style.appendChild( document.createTextNode( css ) );
	}
	head.appendChild( style );
};

function init() {

    csssetup();

	//fb fix
	document.getElementsByTagName('div')[0].style.webkitUserSelect = 'auto';

	setInterval(function() {
		//window.dispatchEvent(new Event('resize'));
		updateTitle();
		dockCount();

		//render settings menu
		if (!document.querySelector('._5v-0._53il')) document.querySelector('._30yy').click();

		var uploadButton = document.querySelector('._m._4q60._3rzn._6a');
		if (uploadButton && uploadButton.onclick==null) {
			uploadButton.onclick = function (e) {
				e.preventDefault();
				e.stopPropagation();
				uploadInfo();
			}
		}
	}, 200);

	setTimeout(function() {
		mixpanel.track("loaded");
	}, 3000);

	document.body.onkeypress=function(e) {
		// If no inputs are focused, or we're at the start of the message input (to prevent system beep), focus the message input and trigger the keypress.
		if ((!document.querySelector(':focus') || (document.querySelector('._54-z:focus') && window.getSelection().baseOffset === 0)) && !e.metaKey && !e.ctrlKey) {
			var char = event.which || event.keyCode;

			// Focus the input at the end of any current text.
			var el = document.querySelector('._54-z');
			var range = document.createRange();
			var sel = window.getSelection();
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

	// Support drag and drop file uploads.
	/*
	document.addEventListener('dragover', function(e) {
		e.stopPropagation();
		e.preventDefault();
		e.dataTransfer.dropEffect = 'copy';
	});

	document.addEventListener('drop', function(e) {
		e.preventDefault();
		e.stopPropagation();

		var uploadInfo = document.getElementById('goofy-upload');
		if (uploadInfo) {
			uploadInfo.parentNode.removeChild(uploadInfo);
		}
		document.querySelector('input[type=file][name="attachment[]"]').files = e.dataTransfer.files;
	});
	*/
	/*
	document.body.addEventListener("DOMNodeInserted", function (ev) {
		if (document.querySelector('._n8')) {
			window.webkit.messageHandlers.notification.postMessage({type: 'SHOW_IMAGE', url: document.querySelector('._4-od').getAttribute('src')});
			document.body.removeChild(document.querySelector('._n8'));
		}
	}, false);
	*/

	document.querySelector('._5743').addEventListener("DOMSubtreeModified", function () {
		updateTitle();
	});
}

function uploadInfo() {
	window.webkit.messageHandlers.notification.postMessage({type: 'CHOOSE_IMAGE'});
}

function updateTitle() {
	var a = ""
	if (document.querySelector('._2v6o')) {
		a = document.querySelector('._2v6o').textContent;
	}
	window.webkit.messageHandlers.notification.postMessage({type: 'SET_TITLE', title: document.querySelector('._5743 span').textContent, activity: a});
}

function newConversation() {
	document.querySelector('._4bl8._4bl7 a').click();
}

function gotoConversation(tag) {
	if (tag==1) {
		document.querySelector('._1ht2').nextElementSibling.firstChild.click();
	} else {
		document.querySelector('._1ht2').previousElementSibling.firstChild.click();
	}
}

function gotoConversationAtIndex(index) {
	document.querySelector('._2xhi._5vn4 ul li:nth-child(' + index + ') a').click()
}

function reactivation(userid) {
	if (userid) {
		document.querySelector('[data-reactid="'+userid+'"] a').click();
	} else if (new Date().getTime() < lastNotificationTime + 1000*60) {
		document.querySelector('._1ht3 a').click();
	}
}

function logout() {
	document.querySelector('._54nf li:last-child a').click();
}

function plus() {
	document.querySelector('._4v._30yy').click();
}

function info() {
	document.querySelector('._fl3._30yy').click();
}

function preferences() {
	document.querySelector('a._54nc').click()
}

function dockCount() {
	var c = document.querySelectorAll('._1ht3:not(._569x)').length;
	if (c != dockCounter) {
		window.webkit.messageHandlers.notification.postMessage({type: 'DOCK_COUNT', content: String(c)});
		dockCounter = c;
	}

	if (c > 0) {
		var latest = document.querySelector('._1ht3');
		var text = latest.querySelector('._1htf');
		if (text) {
			text = text.textContent;
			var subtitle = document.querySelector('._1ht3 ._1ht6').textContent;
			if (lastNotification != subtitle+text) {
				//replacing Facebook smilies with OS X emojis
				[].forEach.call(document.querySelectorAll('._1ht3 ._1htf .emoticon_text'), function(e) {e.textContent = "";});
				[].forEach.call(document.querySelectorAll('._1ht3 ._1htf .emoticon'), function(e) {
					for (a in emoticonMapping) {
						if (e.classList.contains(a)) {
							e.textContent = emoticonMapping[a];
							break;
						}
					}
				});

				text = document.querySelector('._1ht3 ._1htf').textContent;
				var id = document.querySelector('._1ht1._1ht3').getAttribute('data-reactid');

				if (ignoreNotification) {
					ignoreNotification = false;
				} else if (!latest.classList.contains('_569x')) {
					window.webkit.messageHandlers.notification.postMessage({type: 'NOTIFICATION', title: subtitle, text: text, id: id});
					window.webkit.messageHandlers.notification.postMessage({type: 'DOCK_COUNT', content: String(c)});
				}

				lastNotification = subtitle+text;
				lastNotificationTime = new Date().getTime();
			}
		}
	}
}

function replyToNotification(userid, answer) {
	document.querySelector('[data-reactid="'+userid+'"] a').click();
	setTimeout(function () {
		var textEvent = document.createEvent('TextEvent');
		textEvent.initTextEvent('textInput', true, true, null, answer, 9, "en-US");
		document.querySelector('._209g._2vxa').dispatchEvent(textEvent);
		ignoreNotification = true;
		__triggerKeyboardEvent(document.querySelector('._209g._2vxa'),13,true);
	},50);
}

// Handle pasted image data forwarded from the wrapper app.
function pasteImage(base64Data) {
	var blob = b64toBlob(base64Data, 'image/png');
	var uploader = getPhotoUploadComponent();
	uploader._instance.uploadFile(blob);
}

// Convert base64 encoded data to a Blob.
function b64toBlob(b64Data, contentType, sliceSize) {
    contentType = contentType || '';
    sliceSize = sliceSize || 512;

    var byteCharacters = atob(b64Data);
    var byteArrays = [];

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

// Find the instance of the photo upload class from the React component tree.
function getPhotoUploadComponent() {
	var id = '.0.1.$1.0.1.$0.1.0.1.1.0';
	var idComponents = id.split('.');
	var children = __REACT_DEVTOOLS_GLOBAL_HOOK__._reactRuntime.Mount._instancesByReactRootID;
	var component;

	for (var i = 1; i < idComponents.length; i++) {
		var rootId = '.' + idComponents[i];
		component = children[rootId];
		children = getChildren(component);
	}

	return component;
}

// Unwrap the children from a React class instance.
function getChildren(instance) {
	var children = null;
	if (instance._renderedComponent) {
		children = getChildren(instance._renderedComponent);
	} else if (instance._renderedChildren) {
		children = instance._renderedChildren;
	} else {
		children = [];
	}
	return children;
}

function __triggerKeyboardEvent(el, keyCode, meta) {
    var eventObj = document.createEventObject ?
        document.createEventObject() : document.createEvent("Events");

    if(eventObj.initEvent){
      eventObj.initEvent("keydown", true, true);
    }

    eventObj.keyCode = keyCode;
    eventObj.which = keyCode;
	if (meta) {
		eventObj.metaKey = true;
	}

    el.dispatchEvent ? el.dispatchEvent(eventObj) : el.fireEvent("onkeydown", eventObj);

}
