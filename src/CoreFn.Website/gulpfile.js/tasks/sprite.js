var config = require('../config');
var gulp = require('gulp');
var path = require('path');
var spritesmith = require('gulp.spritesmith');
var imagemin = require('gulp-imagemin');
var pngquant = require('imagemin-pngquant');
var plumber = require('gulp-plumber');
var process = require('process');

var task = config.tasks.sprite;

var isWin = /^win/.test(process.platform);

if (!task)
{
    console.log('Unable to find task "sprite" in config.js');
}

gulp.task('sprite', function () {
  var spriteData = 
  gulp.src(path.join(config.root.src, task.src, '**/*.png'))
    .pipe(plumber())
    .pipe(spritesmith({
      retinaSrcFilter: [path.join(config.root.src, task.src, '**/*@2x.png')],
      imgName: task.imgName,
      retinaImgName: task.retinaImgName,
      imgPath: './img/' + task.imgName,
      retinaImgPath: './img/' + task.retinaImgName,
      cssName: task.cssName
    }));
  
  var pipe = spriteData.img;
  if (!isWin)
  {
    pipe = spriteData.img
      .pipe(imagemin({
              progressive: true,
              svgoPlugins: [{removeViewBox: false}],
              use: [pngquant()]
          }))
  }
    pipe.pipe(gulp.dest(path.join(config.root.dest, task.dest)));
  spriteData.css.pipe(gulp.dest(task.cssDest));
});