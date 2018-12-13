import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';

const plugins = loadPlugins();

gulp.task('minify', () => {
  // Minify CSS
  const css = gulp.src(`${config.outputPath}/${config.cssDirectory}/*.css`)
    .pipe(plugins.minifyCss())
    .pipe(gulp.dest(`${config.outputPath}/${config.cssDirectory}`));

  return css;
});
