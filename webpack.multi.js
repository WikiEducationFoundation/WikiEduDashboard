const path = require('path');
const webpack = require('webpack');
const config = require('./config');

// plugins
const ExcludeAssetsPlugin = require('webpack-exclude-assets-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const WebpackRTLPlugin = require('webpack-rtl-plugin');

const plugins = [];

const appRoot = path.resolve('./');
const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
const cssSource = `./${config.sourcePath}/${config.cssDirectory}`;

const jsEntries = [
  { main: [`${jsSource}/main.js`] },
  { raven: [`${jsSource}/raven.js`] },
  { styleguide: [`${jsSource}/styleguide/styleguide.jsx`] },
  { survey: [`${jsSource}/surveys/survey.js`] },
  { survey_admin: [`${jsSource}/surveys/survey-admin.js`] },
  { survey_results: [`${jsSource}/surveys/survey-results.jsx`] },
  { campaigns: [`${jsSource}/campaigns.js`] },
  { charts: [`${jsSource}/charts.js`] },
  { tinymce: [`${jsSource}/tinymce.js`] },
  { embed_course_stats: [`${jsSource}/embed_course_stats.js`] },
];

const cssEntries = [
  { main: [`${cssSource}/main.styl`] },
  { styleguide: [`${cssSource}/styleguide.styl`] },
  { surveys: [`${cssSource}/surveys.styl`] },
  { training: [`${cssSource}/training.styl`] },
];

const cssConfig = env => ({
  resolve: {
    extensions: ['.styl'],
    symlinks: false,
  },
  plugins: [
    // extracts CSS to a separate file
    new MiniCssExtractPlugin({
      filename: env.development ? '../stylesheets/[name].css' : '../stylesheets/[name].[hash].css',
    }),
    // generates a RTL version of the emitted CSS files
    new WebpackRTLPlugin({
      filename: env.development ? '../stylesheets/rtl-[name].css' : '../stylesheets/rtl-[name].[contenthash].css'
    }),
    // css-loader generates unnecesary js files.
    // this will remove that.
    new ExcludeAssetsPlugin({
      path: ['^.*\\.js$']
    })
  ],
  module: {
    rules: [
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
      }
    ]
  }
});

module.exports = (env) => {
  const doHot = env.development && !env.watch_js;
  const mode = env.development ? 'development' : 'production';
  const outputPath = doHot
    ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`)
    : path.resolve(`${config.outputPath}/${config.jsDirectory}`);

  const baseConfig = {
    mode,
    output: {
      path: outputPath,
      filename: doHot ? '[name].js' : '[name].[chunkhash].js',
      publicPath: '/',
    },
    watch: env.watch_js,
    devtool: env.development ? 'eval' : 'source-map',
    devServer: {
      port: 8080,
      contentBase: path.join(__dirname, 'public'),
      writeToDisk: true,
    },
    stats: 'minimal',
  };

  // set node environment
  plugins.push(
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(mode),
      },
    })
  );

  return jsEntries.map((entry) => {
    return {
      ...baseConfig,
      entry,
      resolve: {
        extensions: ['.js', '.jsx'],
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
        ],
      },
      externals: {
        jquery: 'jQuery',
        'i18n-js': 'I18n',
      },
      plugins: [...plugins, new ManifestPlugin({
        fileName: `${Object.keys(entry)[0]}-manifest.json`
      })]
    };
  }).concat(cssEntries.map((entry) => {
    return {
      entry,
      ...baseConfig,
      ...cssConfig(env),
      plugins: [
        ...plugins, ...cssConfig(env).plugins,
        new ManifestPlugin({
          fileName: `${Object.keys(entry)[0]}-css-manifest.json`,
          map: (file) => {
            if (/rtl-.*\.css$/.test(file.path)) {
              file.name = `rtl-${file.name}`;
            }
            return file;
          }
        })
      ]
    };
  }));
};
