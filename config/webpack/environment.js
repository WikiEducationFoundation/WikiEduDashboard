/* eslint prefer-arrow-callback: 0 */
const { environment } = require('@rails/webpacker');
const config = require('./config');
const webpack = require('webpack');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const WebpackShellPlugin = require('webpack-shell-plugin');
const ExtractTextPlugin = require("extract-text-webpack-plugin");

/*
* CLEAN FILES BEFORE BUILD
*/
const pathsToClean = [
  `${config.outputPath}/fonts`,
  `${config.outputPath}/images`,
  `${config.outputPath}/stylesheets`,
  `${config.outputPath}/javascripts`,
];

const cleanOptions = {
  exclude: [`!${config.outputPath}/javascripts/jquery-uls.js`],
};

environment.plugins.append(
  'CleanWebpack',
  new CleanWebpackPlugin(pathsToClean, cleanOptions)
);

/*
* jQuery uls
*/

environment.plugins.append(
  'CommonChunks',
  new webpack.optimize.CommonsChunkPlugin({
    name: 'assets/javascripts/jquery-uls',
    filename: 'jquery-uls.js',
    minChunks: Infinity,
  })
);

environment.entry['jquery-uls'] = [
  './node_modules/@bower_components/jquery/dist/jquery.js',
  './node_modules/@bower_components/lodash/lodash.js',
  './node_modules/@bower_components/jquery.uls/src/jquery.uls.data.js',
  './node_modules/@bower_components/jquery.uls/src/jquery.uls.data.utils.js',
  './node_modules/@bower_components/jquery.uls/src/jquery.uls.lcd.js',
  './node_modules/@bower_components/jquery.uls/src/jquery.uls.languagefilter.js',
  './node_modules/@bower_components/jquery.uls/src/jquery.uls.core.js',
];

/*
* COPY IMAGES AND FONTS
*/
const copyOptions = ['images', 'fonts'].map(function (assetType) {
  return {
    from: `${config.sourcePath}/${assetType}`,
    to: `../assets/${assetType}`,
  };
});

environment.plugins.append(
  'CopyWebpack',
  new CopyWebpackPlugin(copyOptions)
);

/*
* STYLESHEETS
*/

// add entry and output for each style sheet
config.entryStyleSheets.forEach(function (sheetName) {
  environment.entry[`stylesheet-${sheetName}`] = `./${config.sourcePath}/${config.stylesheetsDirectory}/${sheetName}.styl`;
});

environment.loaders.append('styl', {
  test: /\.styl$/,
  loader: ExtractTextPlugin.extract({ fallback: 'style-loader', use: ['css-loader', 'stylus-loader'] }),
});

environment.plugins.append(
  'ExtractText',
  new ExtractTextPlugin(`[name].css`)
);

environment.loaders.append('images', {
  test: /\.(gif|png|jpe?g|svg)$/i,
  use: [
    'file-loader',
    {
      loader: 'image-webpack-loader',
      options: {
        bypassOnDebug: true,
      },
    },
  ],
});

// pre and post build scripts to run
environment.plugins.append(
  'WebpackShell',
  new WebpackShellPlugin({
    onBuildStart: ['bundle exec rake i18n:js:export'],
    onBuildEnd: []
  })
);

module.exports = environment;
