import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import config from '../config.js';
import runSequence from 'run-sequence';

gulp.task('copy-images', () => {
  return gulp.src(`${config.sourcePath}/${config.imagesDirectory}/**/*`)
    .pipe(plugins.plumber())
    .pipe(plugins.newer(`${config.outputPath}/${config.imagesDirectory}`))
    // .pipe(plugins.imagemin({
    //   optimizationLevel: 5
    // }))
    .pipe(gulp.dest(`${config.outputPath}/${config.imagesDirectory}`));
});

gulp.task('copy-fonts', () => {
  return gulp.src(`${config.sourcePath}/${config.fontsDirectory}/**/*`)
    .pipe(gulp.dest(`${config.outputPath}/${config.fontsDirectory}`));
});

gulp.task('copy-static', (cb) => {
  return runSequence(['copy-images', 'copy-fonts'], cb);
});
