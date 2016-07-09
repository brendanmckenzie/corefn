var config = require('../config');
var gulp = require('gulp');
var bourbon = require('node-bourbon');
var browserSync  = require('browser-sync');
var sourcemaps = require('gulp-sourcemaps');
var autoprefixer = require('gulp-autoprefixer');
var rename = require("gulp-rename");
var sass = require('gulp-sass');
var path = require('path');
//var bulkSass = require('gulp-sass-bulk-import');
var notify = require("gulp-notify");
var cssGlobbing = require('gulp-css-globbing');
var cleanCSS = require('gulp-clean-css');
var task = config.tasks.styles;

if (!task)
{
    console.log('Unable to find task "styles" in config.js');
    return;
}

var compile = function(inputFile, outputFile, dist)
{
    console.log('Compiling style to ', path.join(path.join(config.root.dest, task.dest, outputFile)), (dist?' - Dist':' - Dev') + ' mode');
    if (dist)
    {
        gulp.src(inputFile)
            .pipe(cssGlobbing({
                extensions: ['.scss']
            }))
            //.pipe(bulkSass())
            .pipe(sass({
                sourcemap: true,
                style: 'compressed',
                includePaths: bourbon.includePaths,
            }).on('error', sass.logError).on('error', notify.onError(function (error) {
                    return 'An error occurred while compiling sass.\nLook in the console for details.\n' + error;
            })))
            .pipe(autoprefixer({
                browsers: ['last 3 versions', '> 2%'],
                remove: false,
                cascade: false
            }))
            .pipe(cleanCSS({compatibility: 'ie8'}))
            .pipe(rename(outputFile))
            .pipe(gulp.dest(path.join(config.root.dest, task.dest)))
            .pipe(browserSync.stream({match: '**/*.css'}));
    }
    else
    {
        gulp.src(inputFile)
            .pipe(sourcemaps.init())
            .pipe(cssGlobbing({
                extensions: ['.scss']
            }))
            //.pipe(bulkSass())
            .pipe(sass({
                sourcemap: true,
                style: 'compact',
                includePaths: bourbon.includePaths,
            }).on('error', sass.logError).on('error', notify.onError(function (error) {
                    return 'An error occurred while compiling sass.\nLook in the console for details.\n' + error;
            })))
            .pipe(autoprefixer({
                browsers: ['last 3 versions', '> 2%'],
                remove: false,
                cascade: false
            }))
            .pipe(rename(outputFile))
            .pipe(sourcemaps.write('./'))
            .pipe(gulp.dest(path.join(config.root.dest, task.dest)))
            .pipe(browserSync.stream({match: '**/*.css'}));
    }
}

var compileStyles = function(dist)
{
    for(var source of task.sources)
    {
        var inputFile = path.join(config.root.src, task.src, source.input);
        compile(inputFile, source.output, dist);
    }
}
gulp.task('styles', function () {
    compileStyles(false);
});
gulp.task('styles-dist', function () {
    compileStyles(true);
});
