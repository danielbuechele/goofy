# Goofy
Goofy is a macOS client for Facebook Messenger. But unlike most other clients, it does not use any of Facebook's APIs, but is basically a single-site browser that injects a little CSS and JS into [`messenger.com`](https://www.messenger.com/) to make it a little more app-like.

## Feature requests and contributing
Feel free to create issues on this repo for feature requests of any kind. However, some features may not be possible due to the way this application is working. Also, I don't want this to be a feature bloated monster, but a slick and small app. Goofy uses [goofy-core](https://github.com/danielbuechele/goofy-core) as a submodule.

Depending on the number of contributors and the progress of this app, I will schedule releases from time to time, which will then be distributed on [`goofyapp.com`](http://www.goofyapp.com/) and via Sparkle.

## Building and debugging

Clone the repository [along with submodules](http://stackoverflow.com/a/4438292/1470607).

```bash
git clone --recursive https://github.com/danielbuechele/goofy.git
```

If you've already cloned the repository, you can easily clone the submodules:

```bash
cd goofy
git submodule update --init --recursive
```

Install all dependencies and run the app:

```bash
npm i && npm start
```

The developer tools will open automatically when running in development mode. You can also toggle them from the menu `View - Toggle Developer Tools` or by using <kbd>CMD + ALT + I</kbd>.

### Common errors

If you're getting the following error when running `npm start` you're probably missing [goofy-core](https://github.com/danielbuechele/goofy-core/), be sure to clone the submodules along with the main repository.

```bash
Error: ENOENT: no such file or directory, open 'app/src/config/env.json'
```
