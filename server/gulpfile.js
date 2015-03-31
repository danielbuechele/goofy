var gulp = require('gulp');
var uglify = require('gulp-uglify');
var minifyCSS = require('gulp-minify-css');
var insert = require('gulp-insert');
var tap = require('gulp-tap');

gulp.task('default', function () {
    gulp.src('./src/fb.css').pipe(minifyCSS()).pipe(tap(function (file,t) {
        var css = file.contents.toString('utf8');
        gulp.src('./src/fb.js').pipe(uglify()).pipe(insert.prepend("var css='"+css+"';")).pipe(gulp.dest('./dist/'));
    }));
});
