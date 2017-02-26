var fs = require('fs');
var pjson = require('./package.json');

fs.writeFileSync(
	'app/src/config/env.json',
	JSON.stringify({
		name: process.env.NODE_ENV || 'development',
		appName: pjson.build.productName,
		product: 'workplace', // 'workplace' or 'www'
		updateURL: 'https://goofy-nuts.herokuapp.com/update',
	})
);
