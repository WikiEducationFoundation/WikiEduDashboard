import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import webpack from 'webpack';
import WebpackDevServer from 'webpack-dev-server';

gulp.task('webpack-build', ['bower'], plugins.shell.task(['npm run build']));

gulp.task('webpack-dev', (cb) => {
  const config = require('../../config/webpack/webpack.config.dev.js');

  new WebpackDevServer(webpack(config), {
    stats: 'errors-only'
  }).listen(8080, 'localhost', (err) => {
    if (err) {
      throw new plugins.util.PluginError('webpack-dev-server', err);
    }

    return plugins.util.log('[webpack-dev-server] Running');
  });

  plugins.shell.task(['npm run hotdev']);

  cb();
});
