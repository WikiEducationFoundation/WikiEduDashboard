const path = require('path');
const config = require('./config');
const ExcludeAssetsPlugin = require('webpack-exclude-assets-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const WebpackRTLPlugin = require('webpack-rtl-plugin');
const webpack = require('webpack');

const cssSource = `./${config.sourcePath}/${config.cssDirectory}`;
const appRoot = path.resolve('./');
const entry = {
  main: [`${cssSource}/main.styl`],
  styleguide: [`${cssSource}/styleguide.styl`],
  surveys: [`${cssSource}/surveys.styl`],
  training: [`${cssSource}/training.styl`],
};

module.exports = (env) => {
  const doHot = env.development && !env.watch_js;
  const mode = env.development ? 'development' : 'production';
  const outputPath = doHot
    ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`)
    : path.resolve(`${config.outputPath}/${config.jsDirectory}`);

  return {
    mode,
    entry,
    output: {
      path: outputPath,
      filename: doHot ? '[name].styl' : '[name].[chunkhash].styl',
      publicPath: '/',
    },
    resolve: {
      extensions: ['.styl'],
      symlinks: false,
    },
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
    },
    plugins: [
      // extracts CSS to a separate file
      new MiniCssExtractPlugin({
        filename: env.development ? '../stylesheets/[name].css' : '../stylesheets/[name].[hash].css',
      }),
      // generates a RTL version of the emitted CSS files
      // this is done only in production
      ...(env.production || env.coverage ? [new WebpackRTLPlugin({
        filename: '../stylesheets/rtl-[name].[contenthash].css'
      })] : []),
      // css-loader generates unnecesary js files (but with .styl extension)
      // the following will remove that
      new ExcludeAssetsPlugin({
        path: ['^.*\\.styl$']
      }),
      // manifest file
      new ManifestPlugin({
        fileName: 'css-manifest.json',
        map: (file) => {
          if (/rtl-.*\.css$/.test(file.path)) {
            file.name = `rtl-${file.name}`;
          }
          return file;
        }
      }),
      // node environment
      new webpack.DefinePlugin({
        'process.env': {
          NODE_ENV: JSON.stringify(mode),
        },
      })
    ],
    watch: env.watch_js,
    devtool: env.development ? 'eval' : 'source-map',
    stats: 'minimal',
  };
};
