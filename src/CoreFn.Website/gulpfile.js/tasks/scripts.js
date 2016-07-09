var config = require('../config');
var path = require('path');
var gulp = require('gulp');
var glob = require('glob');
var browserSync  = require('browser-sync');
var sourcemaps = require('gulp-sourcemaps');
var babel = require('babelify');
var watchify = require('watchify');
var debowerify = require('debowerify');
var browserify = require('browserify');
var source = require('vinyl-source-stream');
var buffer = require('vinyl-buffer');
var merge = require('utils-merge');
var duration = require('gulp-duration');
var task = config.tasks.scripts;

var getInputFile = function()
{
    var inputFile = task.input;

    if (!inputFile instanceof Array)
    {
        inputFile = [inputFile]
    }

    inputFile = inputFile.map(function(file) {
        return glob.sync(path.join(config.root.src, task.src, file));    
    }).reduce(function(a, b) { return a.concat(b); });

    return inputFile.sort();
}

var getBundler = function(inputFile, watch)
{
    var args = {
        debug: true, delay: 0
    };
    if (watch)
    {
        args = merge(watchify.args, args);
    }

    var browserifyBundle = browserify(inputFile, args);
    if (watch)
    {
        browserifyBundle = browserifyBundle.plugin(watchify, {delay: 0}) // Watchify to watch source file changes
    }
    browserifyBundle = browserifyBundle.transform(babel, {presets: ["es2015", "react" ,"stage-1"],"plugins": ["transform-decorators-legacy", "add-module-exports"], compact: false});
    return browserifyBundle;
}

var firstTimeBundling = true;

if (!task)
{
    console.error('Unable to find task "scripts" in config.js');
}

var bundler = null;

function rebundle(minified) {
    if (minified)
    {
        bundler
            .plugin('minifyify', {map: 'min.json', output: path.join(config.root.dest, task.dest) + '.min.json'})
            .bundle()
            .on('log', function(log) { console.log(log); })
            .on('error', function (err) { console.error(err); this.emit('end'); })
            .pipe(source(task.output))
            .pipe(buffer())
            .pipe(duration('Bundling javascript with minifyify'))
            .pipe(gulp.dest(path.join(config.root.dest, task.dest)))
            .pipe(browserSync.stream({match: '**/*.js'}));
    }
    else
    {
        bundler
            .bundle()
            .on('log', function(log) { console.log(log); })
            .on('error', function (err) { console.error(err); this.emit('end'); })
            .pipe(source(task.output))
            .pipe(buffer())
            .pipe(sourcemaps.init({ loadMaps: true }))
            .pipe(sourcemaps.write('./'))
            .pipe(duration('Bundling javascript'))
            .pipe(gulp.dest(path.join(config.root.dest, task.dest)))
            .pipe(browserSync.stream({match: '**/*.js'}));
    }
}

function compile(watch) {
    if (!watch)
    {
        rebundle(true);
        return;
    }
	
    if (firstTimeBundling) {
        firstTimeBundling = false;
        bundler.on('update', function() {
            console.log('-> Rebundling JS...');
            rebundle(!watch);
        });
        rebundle(!watch);
    }
}

var oldInputList = [];

function setup(watch) {
    var newInputList = getInputFile();

    if (newInputList.length != oldInputList.length)
    {
        firstTimeBundling = true;
    }
    else
    {
        for(var i = 0; i < newInputList.length; i++)
        {
            if (newInputList[i] != oldInputList[i])
            {
                firstTimeBundling = true;
            }
        }
    }

    if (firstTimeBundling)
    {
        console.log('== New list of scripts to bundle ==', newInputList);
        if (bundler)
        {
            bundler.close();
            bundler = null;
        }
    }

    if (!bundler)
    {
        bundler = getBundler(newInputList, watch);
    }

    oldInputList = newInputList;

    compile(watch);
}

gulp.task('scripts-nowatch', function () {
    setup(false);
});

gulp.task('scripts', function () {
    setup(true);
});