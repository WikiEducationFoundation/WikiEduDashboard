const path = require('path');
const spawn = require('child_process').spawn;
const webpack = require('webpack');
const config = require('./config');

// plugins
const CopyPlugin = require('copy-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const ExcludeAssetsPlugin = require('webpack-exclude-assets-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const WebpackRTLPlugin = require('webpack-rtl-plugin');

const plugins = [];

const appRoot = path.resolve('./');
const absoluteOutputPath = path.join(process.cwd(), config.outputPath);
const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
const cssSource = `./${config.sourcePath}/${config.cssDirectory}`;
const jqueryUlsPath = './node_modules/jquery/dist/jquery.min.js';
const cleanPaths = [
  `${config.outputPath}/fonts/*`,
  `${config.outputPath}/images/*`,
  `${config.outputPath}/stylesheets/*`,
  `${config.outputPath}/javascripts/*`,
];
const entries = {
  main: [`${jsSource}/main.js`, `${cssSource}/main.styl`],
  raven: [`${jsSource}/raven.js`],
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

  // clean
  plugins.push(
    new CleanWebpackPlugin({
      cleanOnceBeforeBuildPatterns: cleanPaths.map(relative =>
        path.join(process.cwd(), relative)
      ),
    })
  );

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

  // generates i18n files from rake task after the assets have been emitted
  plugins.push({
    apply: (compiler) => {
      compiler.hooks.afterEmit.tap('AfterEmitPlugin', (_) => {
        spawn('bundle', ['exec', 'rails', 'i18n:js:export'], {
          stdio: 'inherit'
        });
      });
    },
  });

  // copy static assets
  plugins.push(
    new CopyPlugin({
      patterns: [
        {
          from: jqueryUlsPath,
          to: `${absoluteOutputPath}/${config.jsDirectory}`,
        },
        {
          from: `${config.sourcePath}/${config.imagesDirectory}`,
          to: `${absoluteOutputPath}/${config.imagesDirectory}`,
        },
        {
          from: `${config.sourcePath}/${config.fontsDirectory}`,
          to: `${absoluteOutputPath}/${config.fontsDirectory}`,
        },
        {
          from: './node_modules/tinymce/skins',
          to: `${absoluteOutputPath}/${config.jsDirectory}/skins`,
        },
      ],
    })
  );

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
    watch: env.watch_js,
    devtool: env.development ? 'eval' : 'source-map',
    devServer: {
      port: 8080,
      contentBase: path.join(__dirname, 'public'),
      writeToDisk: true,
    },
    stats: 'minimal',
    plugins,
  };
};
