'use strict';

const { whenUIChromeLoaded, isPreviousMessengerVersion } = require('./helpers/common');

function bindStyles() {
	/**
	 * Handling the old messenger.com style (new version of messenger.com was 
	 * released ~May 2019 and slowly rolled out to all users). 
	 * 
	 * Checks for a CSS class in the pre-May 2019 version and if found, apply 
	 * the old .css for it.  
	 */
	whenUIChromeLoaded(() => {
		if (isPreviousMessengerVersion()) {
			const classList = document.querySelector('#facebook').classList;
			if (!classList.contains('goofy343')) {
				classList.add('goofy343');
			}
		}
	});

	// Add drag handle for login screen
	document.addEventListener('DOMContentLoaded', () => {
		const loginBodyElem = document.querySelector('._3v_o');
		if (!loginBodyElem) {
			return;
		}
		const draggableHeader = document.createElement('div');
		draggableHeader.style = '-webkit-app-region: drag; height: 40px;';
		document.querySelector('body').appendChild(draggableHeader);
	});
	
	// Add drag handle for left column
	whenUIChromeLoaded(() => {
		const leftColumnElem = document.querySelector('._1enh._7q1s');
		const leftColumnBeforeElem = document.querySelector('._6-xk');
		const draggableLeftColumnHeaderElem = document.querySelector('.draggableLeftColumnHeader');
		if (!leftColumnElem || !leftColumnBeforeElem || draggableLeftColumnHeaderElem) {
			return;
		}
		const draggableHeader = document.createElement('div');
		draggableHeader.className = 'draggableLeftColumnHeader';
		draggableHeader.style = '-webkit-app-region: drag; height: 28px;';
		leftColumnElem.insertBefore(draggableHeader, leftColumnBeforeElem);
	});
}

module.exports = bindStyles;
