import gulp from 'gulp';
import config from '../config.js';
import flipper from 'gulp-css-flipper';
import rename from 'gulp-rename';
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
      .pipe(plugins.rev()) // apply revision hash to the file name
      .pipe(gulp.dest(styleDir)) // save the files
      .pipe(plugins.rev.manifest()) // create rev.manifest file with the revision hashes
      .pipe(revDel({ dest: styleDir }))
      .pipe(gulp.dest(styleDir));

    // Generate RTL stylesheets
    versionedStream.on('end', () => {
      gulp.src([`${styleDir}/${config.cssMainFiles}.css`])
        .pipe(plugins.rev()) // apply revision hashes before flipping,
                             // so it matches the already-created rev.manifest
        .pipe(flipper()) // do the css flip
        .pipe(rename({ prefix: 'rtl-' })) // add the file prefix rtl-
        .pipe(gulp.dest(styleDir)); // save in the same directory
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
