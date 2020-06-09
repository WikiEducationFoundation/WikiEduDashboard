const path = require('path');
const webpack = require('webpack');
const config = require('./config');

const ExcludeAssetsPlugin = require('webpack-exclude-assets-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const WebpackRTLPlugin = require('webpack-rtl-plugin');
const LodashModuleReplacementPlugin = require('lodash-webpack-plugin');

const plugins = [];

const appRoot = path.resolve('./');

const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
const cssSource = `./${config.sourcePath}/${config.cssDirectory}`;
const entries = {
  main: [`${jsSource}/main.js`, `${cssSource}/main.styl`],
  sentry: [`${jsSource}/sentry.js`],
  styleguide: [`${jsSource}/styleguide/styleguide.jsx`, `${cssSource}/styleguide.styl`],
  survey: [`${jsSource}/surveys/survey.js`],
  survey_admin: [`${jsSource}/surveys/survey-admin.js`],
  survey_results: [`${jsSource}/surveys/survey-results.jsx`],
  campaigns: [`${jsSource}/campaigns.js`],
  charts: [`${jsSource}/charts.js`],
  tinymce: [`${jsSource}/tinymce.js`],
  embed_course_stats: [`${jsSource}/embed_course_stats.js`],
  surveys: [`${cssSource}/surveys.styl`],
  training: [`${cssSource}/training.styl`],
};

module.exports = (env) => {
  const doHot = env.development && !env.watch_js;
  const mode = env.development ? 'development' : 'production';
  const outputPath = doHot
    ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`)
    : path.resolve(`${config.outputPath}/${config.jsDirectory}`);

  // extracts CSS to a separate file
  plugins.push(new MiniCssExtractPlugin({
    filename: env.development ? '../stylesheets/[name].css' : '../stylesheets/[name].[hash].css',
  }));

  // generates a RTL version of the emitted CSS files
  plugins.push(new WebpackRTLPlugin({
    filename: env.development ? '../stylesheets/rtl-[name].css' : '../stylesheets/rtl-[name].[contenthash].css'
  }));

  // css-loader generates unnecesary js files.
  // this will remove that.
  plugins.push(new ExcludeAssetsPlugin({
    path: ['^.*css.*\\.js$']
  }));

  // Creates smaller Lodash builds by replacing feature sets of modules with noop,
  // identity, or simpler alternatives.
  plugins.push(new LodashModuleReplacementPlugin(config.requiredLodashFeatures));

  if (doHot) {
    // wrap entries with hot hooks
    Object.keys(entries).forEach((key) => {
      entries[key] = [
        'webpack-dev-server/client?http://localhost:8080',
        'webpack/hot/only-dev-server',
      ].concat(entries[key]);
    });

    // add hot plugin
    plugins.push(new webpack.HotModuleReplacementPlugin());
  } else {
    // use manifests for non hot builds
    plugins.push(
      new ManifestPlugin({
        fileName: 'rev-manifest.json',
        map: (file) => {
          if (/rtl-.*\.css$/.test(file.path)) {
            file.name = `rtl-${file.name}`;
          }
          return file;
        },
      })
    );
  }

  // set node environment
  plugins.push(
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(mode),
      },
    })
  );

  return {
    mode,
    entry: entries,
    output: {
      path: outputPath,
      filename: doHot ? '[name].js' : '[name].[chunkhash].js',
      publicPath: '/',
    },
    resolve: {
      extensions: ['.js', '.jsx', '.styl'],
      symlinks: false
    },
    module: {
      rules: [
        {
          test: /\.jsx?$/,
          exclude: [/vendor/, /node_modules(?!\/striptags)/],
          use: {
            loader: 'babel-loader',
            query: {
              cacheDirectory: true,
            },
          },
        },
        {
          test: /\.jsx?$/,
          exclude: [/vendor/, /node_modules(?!\/striptags)/],
          loader: 'eslint-loader',
          options: {
            cache: true,
            failOnError: !!env.production
          },
        },
        {
          test: /\.styl$/,
          use: [
            {
              loader: MiniCssExtractPlugin.loader,
              options: {
                hmr: !!env.development
              }
            },
            'css-loader',
            {
              // Compiles Stylus to CSS
              loader: 'stylus-native-loader',
              options: {
                includeCSS: true,
                vendors: true
              }
            }
          ]
        },
        {
          test: /\.(png|jpe?g|gif|svg|eot|ttf|woff|woff2)$/i,
          loader: 'url-loader',
          options: {
            limit: 8192,
          },
        },
      ],
    },
    externals: {
      jquery: 'jQuery',
      'i18n-js': 'I18n',
    },
    optimization: {
      splitChunks: {
        chunks: 'all',
        name: 'vendors'
      },
    },
    watch: env.watch_js,
    devtool: env.development ? 'eval' : 'source-map',
    devServer: {
      port: 8080,
      contentBase: path.join(__dirname, 'public'),
      writeToDisk: true,
    },
    stats: env.stats ? 'normal' : 'minimal',
    plugins,
  };
};
