import gulp from 'gulp';
import gutil from 'gulp-util';
import { exec } from 'child_process';

gulp.task('i18n', cb =>
  exec('bundle exec rake i18n:js:export', (err, stdout, stderr) => {
    if (stdout) {
      gutil.log(stdout);
    }
    if (stderr) {
      gutil.log(stderr);
    }
    return cb(err);
  })
);
