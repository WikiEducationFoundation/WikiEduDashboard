import gulp from 'gulp';
import del from 'del';
import config from '../config.js';

gulp.task('clean', () => {
  return del([
    `${config.outputPath}/fonts/*`,
    `${config.outputPath}/images/*`,
    `${config.outputPath}/stylesheets/*`,
    `!${config.outputPath}/javascripts/jquery-uls.js`,
    `${config.outputPath}/javascripts/*`
  ]);
});
