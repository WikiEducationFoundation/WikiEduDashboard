import path from 'path';
import webpack from 'webpack';
import ManifestPlugin from 'webpack-manifest-plugin';
import config from '../config.js';

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
  campaigns: [`${jsSource}/campaigns.js`],
  charts: [`${jsSource}/charts.js`]
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
}

const outputPath = doHot ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`) : path.resolve(`${config.outputPath}/${config.jsDirectory}`);

module.exports = {
  mode: config.development ? 'development' : 'production',
  entry: entries,
  output: {
    path: outputPath,
    filename: doHot ? '[name].js' : '[name].[hash].js'
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
  plugins: wpPlugins,
  devtool: config.development ? 'eval' : 'source-map'
};
