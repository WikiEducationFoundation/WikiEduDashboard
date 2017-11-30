//--------------------------------------------------------
// Requirements
//--------------------------------------------------------

import gulp from 'gulp';

import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import config from '../config.js';

const mainBowerFiles = ['../../vendor/jquery/dist/jquery.js',
  '../../vendor/jquery-ujs/src/rails.js',
  '../../vendor/list.js/dist/list.js',
  '../../vendor/lodash/lodash.js',
  '../../vendor/moment/moment.js',
  '../../vendor/moment-recur/moment-recur.js',
  '../../vendor/trix/dist/trix.js',
  '../../vendor/jquery.uls/src/jquery.uls.data.js',
  '../../vendor/jquery.uls/src/jquery.uls.data.utils.js',
  '../../vendor/jquery.uls/src/jquery.uls.lcd.js',
  '../../vendor/jquery.uls/src/jquery.uls.languagefilter.js',
  '../../vendor/jquery.uls/src/jquery.uls.core.js'];


//--------------------------------------------------------
// Concatenate Bower libraries
//--------------------------------------------------------

gulp.task('bower', () => {
  return gulp.src(mainBowerFiles)
    .pipe(plugins.concat('vendor.js'))
    .pipe(gulp.dest(`${config.outputPath}/${config.jsDirectory}`));
});
