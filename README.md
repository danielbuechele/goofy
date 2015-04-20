# Goofy
Goofy is a OS X client for Facebook Messenger. But unlike most other clients, it does not use any of Facebook's APIs, but is basically a single-site browser that injects a little CSS and JS into `facebook.com/messages` to make it a little more app-like.

## Feature requests and contributing
Feel free to create issues on this repo for feature requests of any kind. However, some features may not be possible due to the way this application is working. Also, I don't want this to be a feature bloated monster, but a slick and small app.

Depending on the number of contributors and the progress of this app, I will schedule releases from time to time, which will then be distributed on `goofyapp.com` and via Sparkle.

## This repo
This repo contains the Swift project which is only a small browser and should be pretty self-explanatory.

But it also contains the JS and CSS that is loaded from the server. To compile it run:
```
npm install gulp -g
npm install
gulp
```

You can modify Goofy's `Info.plist` and enter a string value for `GoofyJavaScriptURL` to load the JavaScript from a different URL.
