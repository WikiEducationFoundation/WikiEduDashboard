import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import webpack from 'webpack';
import WebpackDevServer from 'webpack-dev-server';
import config from '../config.js';
import wpConf from './webpack.config.js';
const plugins = loadPlugins();

gulp.task('webpack', ['jquery-uls'], (cb) => {
  const doHot = config.development && !config.watch_js;
  const wp = webpack(wpConf);
  if (doHot) {
    // If hot mode, start webpack with dev server
    new WebpackDevServer(wp, {
      stats: 'errors-only'
    }).listen(8080, 'localhost', (err) => {
      if (err) throw new plugins.util.PluginError('webpack-dev-server', err);
      return plugins.util.log('[webpack-dev-server] Running');
    });
  } else {
    if (config.watch_js) {
      // Start webpack in watch mode
      wp.watch({}, (err, stats) => {
        if (err) throw new plugins.util.PluginError('webpack-dev-server', err);
        plugins.util.log('[webpack-dev-server]', stats.toString({ chunks: false }));
      });
    } else {
      // Run webpack once
      wp.run((err, stats) => {
        if (err) throw new plugins.util.PluginError('webpack-dev-server', err);
        plugins.util.log('[webpack-dev-server]', stats.toString({ chunks: false }));
        cb();
      });
    }
  }
});
