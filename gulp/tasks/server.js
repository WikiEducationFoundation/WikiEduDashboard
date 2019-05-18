import { task, src } from 'gulp';
import loadPlugins from 'gulp-load-plugins';

const plugins = loadPlugins();

task('server', () => src('public')
  .pipe(plugins.webserver({
    port: 3000,
    livereload: true
  }))
);
