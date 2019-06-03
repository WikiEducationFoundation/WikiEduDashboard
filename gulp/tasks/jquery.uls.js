import { task, dest, src } from 'gulp';
// import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';
import concat from 'gulp-concat';

// const plugins = loadPlugins();

//--------------------------------------------------------
// Concatenate jquery-uls libraries
//--------------------------------------------------------
const jqueryUlsPath = 'node_modules/@bower_components/jquery/dist/jquery.js';

task('jquery-uls', () => {
  return src(jqueryUlsPath)
    .pipe(concat('jquery-uls.js'))
    .pipe(dest(`${config.outputPath}/${config.jsDirectory}`));
});
