var path = require('path');

module.exports = {
    root: {
        src: path.join(__dirname, '../public'),
        dest: path.join(__dirname, '../_build')
    },
    watchableTasks: ['scripts', 'styles', 'ejs'],
    tasks: {
        browserSync: {
            server: {
                baseDir: path.join(__dirname, './../_build'),
                index: 'index.html'
            }
        },
        ejs: {
            src: '',
            dest: '',
            extensions: [ 'ejs' ],
			options: { ext: '.html' }
        },
        scripts: {
            src: 'js',
            dest: '',
            input: [ 'main.js' ],
            output: 'scripts.js',
            extensions: [ 'js' ]
        },
        styles: {
            src: 'scss',
            dest: '',
            sources: [
                { input: 'styles.scss', output: 'styles.css' },
            ],
            extensions: [ 'scss', 'sass', 'css' ]
        }
    }
};
