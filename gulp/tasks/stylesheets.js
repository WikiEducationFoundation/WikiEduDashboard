import { task, dest, src } from 'gulp';
import flipper from 'gulp-css-flipper';
import rename from 'gulp-rename';
import revDel from 'rev-del';
import loadPlugins from 'gulp-load-plugins';

import config from '../config.js';

const plugins = loadPlugins();

function stylesheets() {
  const styleDir = `${config.outputPath}/${config.cssDirectory}`;

  const stream = src([`${config.sourcePath}/${config.cssDirectory}/${config.cssMainFiles}.styl`])
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
    .pipe(dest(styleDir));

  return stream.on('end', () => {
    const versionedStream = src([`${config.outputPath}/${config.cssDirectory}/${config.cssMainFiles}.css`])
      .pipe(plugins.rev()) // apply revision hash to the file name
      .pipe(dest(styleDir)) // save the files
      .pipe(plugins.rev.manifest()) // create rev.manifest file with the revision hashes
      .pipe(revDel({ dest: styleDir }))
      .pipe(dest(styleDir));

    // Generate RTL stylesheets
    versionedStream.on('end', () => {
      src([`${styleDir}/${config.cssMainFiles}.css`])
        .pipe(plugins.rev()) // apply revision hashes before flipping,
        // so it matches the already-created rev.manifest
        .pipe(flipper()) // do the css flip
        .pipe(rename({ prefix: 'rtl-' })) // add the file prefix rtl-
        .pipe(dest(styleDir)); // save in the same directory
    });
  });
}

task('stylesheets-livereload', () => {
  const styleDir = `${config.outputPath}/${config.cssDirectory}`;

  return src([`${config.sourcePath}/${config.cssDirectory}/${config.cssMainFiles}.styl`])
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
    .pipe(dest(styleDir));
});

export default stylesheets;
