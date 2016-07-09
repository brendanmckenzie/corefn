var config = require('../config');
var gulp        = require('gulp');
var browserSync = require('browser-sync');

gulp.task('browserSync', function() {
    browserSync(config.tasks.browserSync);
});