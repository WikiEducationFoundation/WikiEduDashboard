import { task, series, watch } from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';

const plugins = loadPlugins();

task('watch', () => {
  plugins.watch(`${config.sourcePath}/${config.cssDirectory}/**/*.{styl,sass,scss,css}`, () => {
    return series('stylesheets');
  });

  plugins.watch(`${config.sourcePath}/${config.imagesDirectory}/**/*`, () => {
    return series('copy-images');
  });

  plugins.livereload.listen();

  watch(`${config.outputPath}/${config.cssDirectory}/*.css`, (e) => {
    return plugins.livereload.changed(e.path);
  });
  plugins.livereload.listen();
});
