import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import merge from 'merge-stream';
import config from '../config.js';

const plugins = loadPlugins();

gulp.task('minify', () => {
  // Compress Vendor JavaScript
  const vendor = gulp.src(`${config.outputPath}/${config.jsDirectory}/jquery-uls.js`)
    .pipe(plugins.uglify())
    .pipe(gulp.dest(`${config.outputPath}/${config.jsDirectory}/`));

  // Minify CSS
  const css = gulp.src(`${config.outputPath}/${config.cssDirectory}/*.css`)
    .pipe(plugins.minifyCss())
    .pipe(gulp.dest(`${config.outputPath}/${config.cssDirectory}`));

  return merge(vendor, css);
});
