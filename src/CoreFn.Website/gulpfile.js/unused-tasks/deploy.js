var gulp = require('gulp');
var plumber = require('gulp-plumber');
var GulpSSH = require('gulp-ssh');
var config = require('../config');
var fs = require('fs');
var task = config.tasks.deploy;

try {
  task.config.privateKey = fs.readFileSync(task.config.privateKey);
}
catch(error)
{
  console.log('gulp deploy: Unable to read privateKey @ ' + task.config.privateKey)
}
var gulpSSH = new GulpSSH({
  ignoreErrors: true,
  sshConfig: task.config
})
 
gulp.task('deploy', function () {
    return gulp.src(task.localPath)
        .pipe(plumber())
        .pipe(gulpSSH.dest(task.remotePath));	
});