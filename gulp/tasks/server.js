import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();

gulp.task('server', () => {
  return gulp.src('public')
    .pipe(plugins.webserver({
      port: 3000,
      livereload: true
    }));
});
