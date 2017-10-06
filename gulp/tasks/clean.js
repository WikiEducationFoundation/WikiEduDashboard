import gulp from 'gulp';
import config from '../config.js';
import del from 'del';

gulp.task('clean', () => {
  return del([
    `${config.outputPath}/fonts/*`,
    `${config.outputPath}/images/*`,
    `${config.outputPath}/stylesheets/*`,
    `${config.outputPath}/javascripts/*`,
    `!${config.outputPath}/javascripts/vendor.js`
  ]);
});
