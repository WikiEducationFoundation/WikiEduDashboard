import gulp from 'gulp';
import config from '../config.js';

gulp.task('set-development', () => config.development = true);
