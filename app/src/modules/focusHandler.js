// This module allows us to conveniently focus the primary text input
module.exports = function FocusHandler(webview){
	return () => {
		try {
			// Ensure our webview has focus
			webview.focus();
			const width = webview.scrollWidth;
			const height = webview.scrollHeight;
			const contents = webview.getWebContents();

			// Find the input element in the page and fetch its dimensions
			const inputWrapperSelector = 'div._4rv3';
			contents.executeJavaScript(`
				var element = document.querySelector('${inputWrapperSelector}');
				[ element.scrollWidth, element.scrollHeight ];
			`, false).then((measurements) => {
				const wrapperWidth = measurements[0];
				const wrapperHeight = measurements[1];

				// We offset our target by 1px on both axis to avoid border issues
				const x = width - wrapperWidth + 1;
				const y = height - wrapperHeight + 1;

				// Click the top-left corner of the input area so we avoid the thumbs-up button etc
				webview.sendInputEvent({type: 'mouseDown', x: x, y: y, button: 'left', clickCount: 1});
				webview.sendInputEvent({type: 'mouseUp', x: x, y: y, button: 'left', clickCount: 1});
			}).catch(() => {
				// Fail silently
			});
		} catch (_) {
			// Fail silently
		}
	};
};
