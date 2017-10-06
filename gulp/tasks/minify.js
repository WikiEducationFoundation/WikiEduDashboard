import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import config from '../config.js';
import merge from 'merge-stream';

gulp.task('minify', () => {
  // Compress Vendor JavaScript
  const vendor = gulp.src(`${config.outputPath}/${config.jsDirectory}/vendor.js`)
    .pipe(plugins.uglify())
    .pipe(gulp.dest(`${config.outputPath}/${config.jsDirectory}/`));

  // Minify CSS
  const css = gulp.src(`${config.outputPath}/${config.cssDirectory}/*.css`)
    .pipe(plugins.minifyCss())
    .pipe(gulp.dest(`${config.outputPath}/${config.cssDirectory}`));

  return merge(vendor, css);
});
