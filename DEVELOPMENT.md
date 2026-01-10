# Development

## Local Content Script

During development, the extension loads `content.js` from a local server instead of GitHub. This is triggered automatically when the manifest version is `0.0` (Debug builds).

### Start the local server

```bash
npx serve -p 8080 --cors
```

Then open messenger.com in Safari. The extension will fetch `http://localhost:8080/content.js`.

### How it works

- Debug builds keep `version: "0.0"` in manifest.json
- Release builds update the version via Xcode run script
- `background.js` checks the version and uses localhost for `0.0`, GitHub otherwise

## Building

- **Debug**: Run from Xcode, loads content.js from localhost
- **Release**: Archive in Xcode, loads content.js from GitHub
