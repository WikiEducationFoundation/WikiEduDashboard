import { task, series, watch } from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';
import stylesheets from './stylesheets';

const plugins = loadPlugins();

task('watch', () => {
  watch(`${config.sourcePath}/${config.cssDirectory}/**/*.{styl,sass,scss,css}`, stylesheets).on('change', (path) => {
    return plugins.livereload.changed(path);
  });

  watch(`${config.sourcePath}/${config.imagesDirectory}/**/*`, series('copy-static')).on('change', (path) => {
    return plugins.livereload.changed(path);
  });

  plugins.livereload.listen();
});
