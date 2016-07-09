var config = require('../config');
var gulp   = require('gulp');
var watch  = require('gulp-watch');
var path   = require('path');

gulp.task('watch', [], function() {
    config.watchableTasks.forEach(function(taskName) {
        var task = config.tasks[taskName];
        if(task) {
            var filePattern = path.join(config.root.src, task.src, '**/*.{' + task.extensions.join(',') + '}');
            if( task.src2 ){
                var filePattern2 =  path.join(config.root.src, task.src2, '**/*.{' + task.extensions.join(',') + '}');
                filePattern = [filePattern,filePattern2];
            }
            watch(filePattern, function() { gulp.start(taskName) })
        }
    })
});