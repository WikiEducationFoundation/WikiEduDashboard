//--------------------------------------------------------
// Requirements
//--------------------------------------------------------

import gulp from 'gulp';
import mainBowerFiles from 'main-bower-files';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import config from '../config.js';


//--------------------------------------------------------
// Concatenate Bower libraries
//--------------------------------------------------------

gulp.task('bower', () => {
  return gulp.src(mainBowerFiles())
    .pipe(plugins.concat('vendor.js'))
    .pipe(gulp.dest(`${config.outputPath}/${config.jsDirectory}`));
});
