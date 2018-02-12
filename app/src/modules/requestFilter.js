// This module handles all request filtering

module.exports = function RequestFilter(session) {
	let retinaCookie = null;

	const filter = {
		// TODO: Use getURL() or similar here instead?
		urls: [ 'https://*.facebook.com' ],
	};

	session.defaultSession.webRequest.onBeforeSendHeaders(filter, (details, callback) => {
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
			cancel: false,
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
