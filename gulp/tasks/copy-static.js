import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import runSequence from 'run-sequence';
import config from '../config.js';

const plugins = loadPlugins();

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

gulp.task('copy-tinymce-skins', () => {
  return gulp.src('./node_modules/tinymce/skins/**/*')
    .pipe(gulp.dest(`${config.outputPath}/${config.jsDirectory}/skins`));
});

gulp.task('copy-static', (cb) => {
  return runSequence(['copy-images', 'copy-fonts', 'copy-tinymce-skins'], cb);
});
