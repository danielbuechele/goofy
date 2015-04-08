var lastNotification;
var lastNotificationTime;

(function(f,b){if(!b.__SV){var a,e,i,g;window.mixpanel=b;b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");
for(g=0;g<i.length;g++)f(c,i[g]);b._i.push([a,e,d])};b.__SV=1.2;a=f.createElement("script");a.type="text/javascript";a.async=!0;a.src="//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js";e=f.getElementsByTagName("script")[0];e.parentNode.insertBefore(a,e)}})(document,window.mixpanel||[]);
mixpanel.init("2245181dbc803998dedc5b07d840e672");

var emoticonMapping = {
	"emoticon_smile"			:"😃",
	"emoticon_frown"			:"😦",
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
	"emoticon_devil"			:"😈",
	"emoticon_angel"			:"😇",
	"emoticon_kiss"			:"😘",
	"emoticon_heart"			:"❤️",
	"emoticon_kiki"			:"😊",
	"emoticon_squint"		:"😑",
	"emoticon_confused"		:"😕",
	"emoticon_confused_rev"	:"😕",
	"emoticon_upset"			:">:o",
	"emoticon_pacman"		:":v",
	"emoticon_robot"			:":|]",
	"emoticon_colonthree"	:":3",
	"emoticon_penguin"		:"🐧",
	"emoticon_shark"			:"(^^^)",
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

	setInterval(function() {
		window.dispatchEvent(new Event('resize'));
		dockCount();
	}, 200);

	setTimeout(function() {
		mixpanel.track("loaded");
		window.webkit.messageHandlers.notification.postMessage({type: 'URL_CONFIG', backgroundURLs: ["facebook.com/xti.php","facebook.com/ai.php","fbcdn","spotilocal.com","facebook.com/ajax/music","facebook.com/sound_iframe"], inAppURLs: ["facebook.com/messages","facebook.com/login","facebook.com/checkpoint","spotilocal.com","facebook.com/ajax/music","facebook.com/sound_iframe"]});
	}, 3000);

	document.onkeydown = function () {
		var evtobj = window.event? event : e

		if (evtobj.metaKey && evtobj.keyCode==221) {
			//next
			document.querySelector('._kv').nextElementSibling.firstChild.childNodes[1].click();
			return false;
		}

		if (evtobj.metaKey && evtobj.keyCode==78) {
			document.querySelector('._3mv').click();
			return false;
		}

		if (evtobj.metaKey && evtobj.keyCode==219) {
			//prev
			document.querySelector('._kv').previousElementSibling.firstChild.childNodes[1].click();
			return false;
		}

		if (evtobj.keyCode > 48 && evtobj.keyCode < 58 && evtobj.ctrlKey) {
			document.querySelector(".uiList._2tm._4kg li:nth-child("+(evtobj.keyCode-48)+") ._k_").click();
			return false;
		}
	};

}

function reactivation(userid) {
	if (userid) {
		document.getElementById(userid).querySelector('._k_').click();
	} else if (new Date().getTime() < lastNotificationTime + 1000*60) {
		document.querySelector('._kx ._l2').click();
	}
}

function dockCount() {
	var c = document.querySelector('._1z4y .jewelCount ._3z_5').textContent;
	window.webkit.messageHandlers.notification.postMessage({type: 'DOCK_COUNT', content: c});

	if (parseInt(c)>0) {

		//replacing Facebook smilies with OS X emojis
		[].forEach.call(document.querySelectorAll('._kx ._l3 .emoticon_text'), function(e) {e.textContent = "";});
		[].forEach.call(document.querySelectorAll('._kx ._l3 .emoticon'), function(e) {
			for (a in emoticonMapping) {
				if (e.classList.contains(a)) {
					e.textContent = emoticonMapping[a];
					break;
				}
			}
		});

		var subtitle = document.querySelector('._kx ._l2 ._l1').textContent;
		var text = document.querySelector('._kx ._l3').textContent;
		if (lastNotification != subtitle+text) {
			var id = document.querySelector('._kx').id;
			window.webkit.messageHandlers.notification.postMessage({type: 'NOTIFICATION', title: subtitle, text: text, id: id});
			lastNotification = subtitle+text;
			lastNotificationTime = new Date().getTime();
		}
	}
}

function replyToNotification(userid, answer) {
	document.getElementById(userid).querySelector('._l3').click();
	setTimeout(function () {
		document.querySelector('._1rt textarea').value = answer;
		setTimeout(function () {
			document.getElementById('u_0_r').click();
		},50);
	},50);
}
