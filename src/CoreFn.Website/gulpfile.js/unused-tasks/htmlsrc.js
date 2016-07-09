var config = require('../config');
var path = require('path');
var browserSync  = require('browser-sync');
var gulp = require('gulp');
var plumber = require('gulp-plumber');
var task = config.tasks.htmlsrc;

gulp.task('htmlsrc', function(){
    console.log("Updating htmlsrc");
    console.log("Source html: ", path.join(config.root.src, task.src, '**/*.html'));
    return gulp.src(path.join(config.root.src, task.src, '**/*.html'))
    .pipe(plumber())
    .pipe(gulp.dest(path.join(config.root.dest, task.dest)))
    .pipe(browserSync.stream({match: '**/*.html'}));
});