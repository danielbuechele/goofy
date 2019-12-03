'use strict';

const PREV_VERSION_SELECTOR = '._1enh ._36ic._5l-3 ._1tqi';

/**
 * Note, has a bug where sometimes the callback gets called twice. For safety, 
 * if calling this method is recommended to add a check to handle this case.
 */
function whenUIChromeLoaded(callback) {
	let fired = false;
	document.addEventListener('DOMContentLoaded', () => {
		const observer = new MutationObserver(mutations => {
			if (fired) {
				return;
			}
	
			mutations.forEach((mutation) => {
				switch(mutation.type) {
					case 'childList':
						// UI chrome is loaded once left column is loaded
						if (!mutation.target.querySelector('._1enh._7q1s')) {
							return;
						}
						callback();
						fired = true;
						observer.disconnect();
						break;
					default:
						break;
				}
			});
		});

		observer.observe(
			document.querySelector('body'),
			{
				subtree: true,
				childList: true,
			}
		);
	});
}

function isPreviousMessengerVersion() {
	return document.querySelector(PREV_VERSION_SELECTOR) != null;
}

module.exports = {
	whenUIChromeLoaded,
	isPreviousMessengerVersion,
};
