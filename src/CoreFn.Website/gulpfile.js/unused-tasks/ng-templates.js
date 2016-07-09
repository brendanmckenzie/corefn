var config = require('../config');
var gulp = require('gulp');
var path = require('path');
var templateCache = require('gulp-angular-templatecache');

var task = config.tasks.ngTemplates;

if (!task)
{
    console.log('Unable to find task "ngTemplates" in config.js');
}

gulp.task('ngTemplates', function () {
    return gulp.src(path.join(config.root.src, task.src, '**/*.html'))
        .pipe(templateCache(task.output, task.config))
        .pipe(gulp.dest(task.dest));
});
