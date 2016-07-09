var config = require('../config');
var gulp = require('gulp');
var path = require('path');
var plumber = require('gulp-plumber');
var iconfont = require('gulp-iconfont');
var consolidate = require('gulp-consolidate');
var rename = require('gulp-rename');;

var task = config.tasks.iconfont;

if (!task)
{
    console.log('Unable to find task "iconfont" in config.js');
}

gulp.task('iconfont', function(){
  return gulp.src([path.join(config.root.src, task.src, '**/*.svg')])
    .pipe(iconfont(task.config))
    .on('glyphs', function(glyphs, options) {
      var pipe = gulp.src(path.join(config.root.src, task.template))
        .pipe(consolidate('lodash', {
          glyphs: glyphs,
          fontName: 'icons',
          fontPath: './fonts/',
          className: 'icon'
        }))
        .pipe(rename(task.cssName))
        .pipe(gulp.dest(task.cssDest));
    })
    .pipe(gulp.dest(path.join(config.root.dest, task.dest)));
});
