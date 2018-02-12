const jetpack = require('fs-jetpack');
var env = jetpack.cwd(__dirname).read('env.json', 'json');
module.exports = env;
