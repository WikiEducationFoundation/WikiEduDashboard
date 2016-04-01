import gulp from 'gulp';
import config from '../config.js';

gulp.task('set-development', () => config.development = true);

gulp.task('set-watch-js', () => config.watch_js = true);
