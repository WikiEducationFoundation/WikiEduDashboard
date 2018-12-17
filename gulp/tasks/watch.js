import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';

const plugins = loadPlugins();

gulp.task('watch', () => {
  plugins.watch(`${config.sourcePath}/${config.cssDirectory}/**/*.{styl,sass,scss,css}`, () => {
    return gulp.start('stylesheets');
  });

  plugins.watch(`${config.sourcePath}/${config.imagesDirectory}/**/*`, () => {
    return gulp.start('copy-images');
  });

  plugins.livereload.listen();

  gulp.watch(`${config.outputPath}/${config.cssDirectory}/*.css`, (e) => {
    return plugins.livereload.changed(e.path);
  });
  plugins.livereload.listen();
});
