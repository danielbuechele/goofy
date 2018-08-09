// This module handles all request filtering

const userConfig = require('./userConfig');

module.exports = function RequestFilter(session) {
	let retinaCookie = null;

	const filter = {
		// TODO: Use getURL() or similar here instead?
		urls: [
			'https://*.facebook.com',
			`https://*.facebook.com/*typ.php*`,
			`https://*.facebook.com/*change_read_status.php*`,
		],
	};

	session.defaultSession.webRequest.onBeforeSendHeaders(filter, (details, callback) => {
		let cancel = false;

		if (details.url.includes('typ.php')) {
			cancel = userConfig.get('blockTyping');
		} else if (details.url.includes('change_read_status.php')) {
			cancel = userConfig.get('blockSeen');
		}

		const delimiter = '; ';
		const cookieStrings = (details.requestHeaders.Cookie || '').split(delimiter);

		const cookieMap = cookieStrings.reduce((map, item) => {
			const [ name, value ] = item.split('=');
			if (!name) {return map;}
			map[name] = value;
			return map;
		}, {});

		if (retinaCookie) {
			cookieMap.dpr = retinaCookie;
		}

		const newCookieString = Object.keys(cookieMap).map(name => `${name}=${cookieMap[name]}`).join(delimiter);
		details.requestHeaders.Cookie = newCookieString;

		const resolve = {
			cancel: cancel,
			requestHeaders: details.requestHeaders,
		};
		callback(resolve);
	});

	return {
		setRetinaCookie(cookieValue) {
			retinaCookie = cookieValue;
		},
	};
};
