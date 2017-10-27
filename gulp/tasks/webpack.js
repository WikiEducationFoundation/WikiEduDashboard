import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';
import ManifestPlugin from 'webpack-manifest-plugin';
import webpack from 'webpack';
import WebpackDevServer from 'webpack-dev-server';
import path from 'path';
const plugins = loadPlugins();

gulp.task('webpack', ['bower'], (cb) => {
  const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
  const doHot = config.development && !config.watch_js;
  const appRoot = path.resolve('../../');

  const entries = {
    main: [`${jsSource}/main.js`],
    raven: [`${jsSource}/raven.js`],
    styleguide: [`${jsSource}/styleguide/styleguide.jsx`],
    survey: [`${jsSource}/surveys/survey.js`],
    survey_admin: [`${jsSource}/surveys/survey-admin.js`],
    survey_results: [`${jsSource}/surveys/survey-results.jsx`],
    campaigns: [`${jsSource}/campaigns.js`]
  };

  // Set up plugins based on dev/prod mode
  const wpPlugins = [];

  if (doHot) {
    // Wrap entries with hot hooks
    Object.keys(entries).forEach(key => {
      entries[key] = ['webpack-dev-server/client?http://localhost:8080', 'webpack/hot/only-dev-server'].concat(entries[key]);
    });

    // Add hot plugin
    wpPlugins.push(new webpack.HotModuleReplacementPlugin());
  } else {
    // Use manifests for non hot builds
    wpPlugins.push(new ManifestPlugin({
      fileName: 'rev-manifest.json'
    }));
  }

  // For prod
  if (!config.development) {
    // Update NODE_ENV
    wpPlugins.push(new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production')
      }
    }));

    // Minify
    wpPlugins.push(new webpack.optimize.UglifyJsPlugin({
      compress: { warnings: false }
    }));
  }

  const wpConf = {
    entry: entries,
    stats: 'errors-only',
    output: {
      path: doHot ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`) : path.resolve(`${config.outputPath}/${config.jsDirectory}`),
      filename: doHot ? '[name].js' : '[name].[hash].js'
    },
    resolve: {
      extensions: ['.js', '.jsx'],
    },
    module: {
      loaders: [{
        test: /\.jsx?$/,
        exclude: [/vendor/, /node_modules(?!\/striptags)/],
        loader: 'babel-loader',
        query: {
          cacheDirectory: true
        }
      }, {
        test: /\.json$/,
        loader: 'json-loader'
      }]
    },
    externals: {
      jquery: 'jQuery',
      'i18n-js': 'I18n'
    },
    plugins: wpPlugins,
    devtool: config.development ? 'eval' : 'source-map'
  };

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
