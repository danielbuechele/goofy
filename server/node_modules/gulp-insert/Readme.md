# gulp-insert

String manipulation library for gulp

## Usage

```
npm install gulp-insert
```

```js
var insert = require('gulp-insert');
```

## Append

Appends a string onto the contents.

```js
.pipe(insert.append('world')); // Appends 'world' to the contents of every file
```

## Prepend

Appends a string onto the contents.

```js
.pipe(insert.prepend('Hello')); // Prepends 'Hello' to the contents of every file
```
## Wrap

Wraps the contents with two strings.

```js
.pipe(insert.wrap('Hello', 'World')); // prepends 'hello' and appends 'world' to the contents
```

## Transform

Calls a function with the contents of the file.

```js
.pipe(insert.transform(function(contents) {
  return contents.toUpperCase();
}));
```
