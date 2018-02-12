# Goofy
Goofy is a macOS client for Facebook Messenger. But unlike most other clients, it does not use any of Facebook's APIs, but is basically a single-site browser that injects a little CSS and JS into [`messenger.com`](https://www.messenger.com/) to make it a little more app-like.

## Feature requests and contributing
Feel free to create issues on this repo for feature requests of any kind. However, some features may not be possible due to the way this application is working. Also, I don't want this to be a feature bloated monster, but a slick and small app.

Depending on the number of contributors and the progress of this app, I will schedule releases from time to time, which will then be distributed on [`goofyapp.com`](http://www.goofyapp.com/) and via Sparkle.

## Building and debugging

Install all dependencies and run the app:

```bash
npm i && npm start
```

The developer tools will open automatically when running in development mode. You can also toggle them from the menu `View - Toggle Developer Tools` or by using <kbd>CMD + ALT + I</kbd>.
