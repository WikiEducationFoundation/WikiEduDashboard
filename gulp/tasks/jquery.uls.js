import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';
const plugins = loadPlugins();


//--------------------------------------------------------
// Concatenate jquery-uls libraries
//--------------------------------------------------------
const jqueryUlsPath = [
  'node_modules/@bower_components/jquery/dist/jquery.js',
  'node_modules/@bower_components/lodash/lodash.js'
  ];

gulp.task('jquery-uls', () => {
  return gulp.src(jqueryUlsPath)
    .pipe(plugins.concat('jquery-uls.js'))
    .pipe(gulp.dest(`${config.outputPath}/${config.jsDirectory}`));
});
