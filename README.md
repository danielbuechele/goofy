# ⚠️ Goofy is not maintained anymore

Messenger offers a first party desktop now and I encourage all Goofy users to [try it out](https://www.messenger.com/desktop/).


# Goofy

Goofy is a macOS client for Facebook Messenger. But unlike most other clients, it does not use any of Facebook's APIs, but is basically a single-site browser that injects a little CSS and JS into [`messenger.com`](https://www.messenger.com/) to make it a little more app-like.

## Feature requests and contributing

Feel free to create issues on this repo for feature requests of any kind. However, some features may not be possible due to the way this application is working. Also, I don't want this to be a feature bloated monster, but a slick and small app.

Depending on the number of contributors and the progress of this app, I will schedule releases from time to time, which will then be distributed on [`goofyapp.com`](http://www.goofyapp.com/).

## Building and debugging

Install all dependencies and run the app:

```bash
~$ npm i
~$ node_modules/.bin/electron-builder install-app-deps  # Rebuild native modules
~$ npm start
```

Note, the `postinstall` hook hasn't been used in `package.json` to automatically build the native modules after an `npm i`, as there is a weird bug in Travis CI.  I.e. When Travis CI receives a build, it runs an `npm ci` which (for whatever reason) doesn't install `electron-builder` (which builds the native modules) - so when `postinstall` runs it errors.  So instead, we let `npm ci` run without rebuilding the native modules, and then manually add in the step to rebuild the native modules in the `before_script`. Consequently when developing, this step now needs to be run manually.  

To debug, there's a VSCode launch.json that can be used to debug the Electron app. To debug the Facebook JavaScript changes you'll need to use the Chrome Web Inspector, which you can toggle from the menu `View - Toggle Developer Tools` or by using <kbd>CMD + ALT + I</kbd>.

## Distribution

To create a distribution locally:

1. Create an Apple developer account
2. Create an app specific password on your developer account for Goofy https://support.apple.com/en-us/HT204397
3. Run `cp env-sample .env`
4. Edit `.env` and fill in your Apple ID and app specific password (this file is ignored in .gitignore)
5. Run `npm run dist` - note this process might take awhile as it both signs and notarizes the built .app with Apple

In the `./dist` directory will now be the notarized .app along with the packaged files (which are not notarized)
