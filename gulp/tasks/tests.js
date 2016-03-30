import gulp from 'gulp';
import config from '../config.js';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();

gulp.task('test', () => {
  gulp.start('javascripts');

  gulp.src(`${config.testPath}/spec-runner.coffee`, {
    read: false
  })
  .pipe(plugins.plumber())
  .pipe(plugins.browserify({
    transform: ['handleify', 'coffeeify'],
    extensions: ['.coffee', '.js'],
    debug: true
  }))
  .pipe(plugins.rename('spec.js'))
  .pipe(gulp.dest(`${config.testPath}/html`));

  return gulp.src(`${config.testPath}/html/index.html`)
    .pipe(plugins.mochaPhantomjs());
});
