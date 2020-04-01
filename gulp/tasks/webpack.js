import { task, series } from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import webpack from 'webpack';
import path from 'path';
import ManifestPlugin from 'webpack-manifest-plugin';
import WebpackDevServer from 'webpack-dev-server';
import config from '../config.js';

const plugins = loadPlugins();

function startWebpack(cb) {
  const doHot = config.development && !config.watch_js;
  const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
  const appRoot = path.resolve('../../');
  const entries = {
    main: [`${jsSource}/main.js`],
    raven: [`${jsSource}/raven.js`],
    styleguide: [`${jsSource}/styleguide/styleguide.jsx`],
    survey: [`${jsSource}/surveys/survey.js`],
    survey_admin: [`${jsSource}/surveys/survey-admin.js`],
    survey_results: [`${jsSource}/surveys/survey-results.jsx`],
    campaigns: [`${jsSource}/campaigns.js`],
    charts: [`${jsSource}/charts.js`],
    tinymce: [`${jsSource}/tinymce.js`],
    embed_course_stats: [`${jsSource}/embed_course_stats.js`]
  };

  // Set up plugins based on dev/prod mode
  const wpPlugins = [];

  if (doHot) {
    // Wrap entries with hot hooks
    Object.keys(entries).forEach((key) => {
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

  // Update NODE_ENV
  const mode = config.development ? 'development' : 'production';
  wpPlugins.push(new webpack.DefinePlugin({
    'process.env': {
      NODE_ENV: JSON.stringify(mode)
    }
  }));

  const outputPath = doHot ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`) : path.resolve(`${config.outputPath}/${config.jsDirectory}`);
  const wpConf = {
    mode,
    entry: entries,
    output: {
      path: outputPath,
      filename: doHot ? '[name].js' : '[name].[chunkhash].js',
      publicPath: '/'
    },
    resolve: {
      extensions: ['.js', '.jsx'],
    },
    module: {
      rules: [
        {
          test: /\.jsx?$/,
          exclude: [/vendor/, /node_modules(?!\/striptags)/],
          use: {
            loader: 'babel-loader',
            query: {
              cacheDirectory: true
            }
          }
        }
      ]
    },
    externals: {
      jquery: 'jQuery',
      'i18n-js': 'I18n'
    },
    watch: config.watch_js,
    plugins: wpPlugins,
    devtool: config.development ? 'eval' : 'source-map'
  };
  const wp = webpack(wpConf);
  if (doHot) {
    // If hot mode, start webpack with dev server
    new WebpackDevServer(wp, {
      stats: 'errors-only',
    }).listen(8080, 'localhost', (err) => {
      if (err) throw new plugins.util.PluginError('webpack-dev-server', err);
      return plugins.util.log('[webpack-dev-server] Running');
    });
  } else if (config.watch_js) {
    // Start webpack in watch mode
    wp.watch({
      ignored: /node_modules/,
      poll: true
    }, (err, stats) => {
      if (err) throw new plugins.util.PluginError('webpack-watch', err);
      plugins.util.log('[webpack-watch]', stats.toString({ chunks: false }));
    });
  } else {
    // Run webpack once
    wp.run((err, stats) => {
      if (err) throw new plugins.util.PluginError('webpack', err);
      plugins.util.log('[webpack]', stats.toString({ chunks: false }));
      cb();
    });
  }
}
task('webpack', series('jquery-uls', startWebpack));
