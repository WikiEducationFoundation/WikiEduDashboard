import { task, dest, src } from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';

const plugins = loadPlugins();

task('minify', () => {
  // Minify CSS
  const css = src(`${config.outputPath}/${config.cssDirectory}/*.css`)
    .pipe(plugins.cleanCss())
    .pipe(dest(`${config.outputPath}/${config.cssDirectory}`));

  return css;
});
