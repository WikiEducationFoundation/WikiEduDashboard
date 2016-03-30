import gulp from 'gulp';
import config from '../config.js';
import flipper from 'gulp-css-flipper';
import revDel from 'rev-del';

import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();

gulp.task('stylesheets', () => {
  const styleDir = `${config.outputPath}/${config.cssDirectory}`;

  const stream = gulp.src([`${config.sourcePath}/${config.cssDirectory}/${config.cssMainFiles}.styl`])
    .pipe(plugins.plumber())
    .pipe(plugins.stylus({
      'include css': true,
      sourcemap: {
        inline: config.development
      }
    }))
    .pipe(plugins.sourcemaps.init({
      loadMaps: true
    }))
    .pipe(plugins.autoprefixer())
    .pipe(plugins.sourcemaps.write())
    .pipe(gulp.dest(styleDir));

  return stream.on('end', () => {
    const versionedStream = gulp.src([`${config.outputPath}/${config.cssDirectory}/${config.cssMainFiles}.css`])
      .pipe(plugins.rev())
      .pipe(gulp.dest(styleDir))
      .pipe(plugins.rev.manifest())
      .pipe(revDel({ dest: styleDir }))
      .pipe(gulp.dest(styleDir));

    versionedStream.on('end', () => {
      const rtlDir = `${config.outputPath}/${config.cssDirectory}/rtl`;
      gulp.src([`${config.outputPath}/${config.cssDirectory}/${config.cssMainFiles}.css`])
        .pipe(flipper())
        .pipe(plugins.rev())
        .pipe(gulp.dest(rtlDir))
        .pipe(plugins.rev.manifest())
        .pipe(revDel({ dest: rtlDir }))
        .pipe(gulp.dest(rtlDir));
    });
  });
});

gulp.task('stylesheets-livereload', () => {
  const styleDir = `${config.outputPath}/${config.cssDirectory}`;

  return gulp.src([`${config.sourcePath}/${config.cssDirectory}/${config.cssMainFiles}.styl`])
    .pipe(plugins.plumber())
    .pipe(plugins.stylus({
      'include css': true,
      sourcemap: {
        inline: config.development
      }
    }))
    .pipe(plugins.sourcemaps.init({
      loadMaps: true
    }))
    .pipe(plugins.autoprefixer())
    .pipe(plugins.sourcemaps.write())
    .pipe(gulp.dest(styleDir));
});
