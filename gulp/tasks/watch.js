import gulp from 'gulp';
import config from '../config.js';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();

gulp.task('watch', () => {
  plugins.watch(`${config.sourcePath}/${config.cssDirectory}/**/*.{styl,sass,scss,css}`, () => {
    return gulp.start('stylesheets');
  });

  plugins.watch(`${config.sourcePath}/${config.imagesDirectory}/**/*`, () => {
    return gulp.start('copy-images');
  });

  plugins.watch('bower.json', () => {
    return gulp.start('bower');
  });

  plugins.livereload.listen();

  gulp.watch(`${config.outputPath}/${config.cssDirectory}/*.css`, (e) => {
    return plugins.livereload.changed(e.path);
  });
  plugins.livereload.listen();

  if (config.watch_js) {
    gulp.watch(`${config.outputPath}/${config.jsDirectory}/**/**/*.{js,jsx,coffee,cjsx}`, ['webpack-build']);
  }

  return;
});
