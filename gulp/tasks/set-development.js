import gulp from 'gulp';
import config from '../config.js';

gulp.task('set-development', (done) => {
  config.development = true;
  done();
});

gulp.task('set-watch-js', (done) => {
  config.watch_js = true;
  done();
});
