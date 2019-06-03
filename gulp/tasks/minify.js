import { task, dest, src } from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import merge from 'merge-stream';
import config from '../config.js';

const plugins = loadPlugins();

task('minify', () => {
  // Compress Vendor JavaScript
  const vendor = src(`${config.outputPath}/${config.jsDirectory}/jquery-uls.js`)
    .pipe(plugins.uglify())
    .pipe(dest(`${config.outputPath}/${config.jsDirectory}/`));

  // Minify CSS
  const css = src(`${config.outputPath}/${config.cssDirectory}/*.css`)
    .pipe(plugins.minifyCss())
    .pipe(dest(`${config.outputPath}/${config.cssDirectory}`));

  return merge(vendor, css);
});
