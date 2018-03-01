/* eslint prefer-arrow-callback: 0 */
const { environment } = require('@rails/webpacker');
const config = require('./config')
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin')
const WebpackShellPlugin = require('webpack-shell-plugin');

// scripts to run before and after build
const onBuildStart = [];

/*
* I18N
*/
onBuildStart.push('bundle exec rake i18n:js:export');

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
* COPY IMAGES AND FONTS
*/
const copyOptions = ['images', 'fonts'].map(function (assetType) {
  return {
    from: `${config.sourcePath}/${assetType}`,
    to: `${assetType}`,
  };
});

environment.plugins.append(
  'CopyWebpack',
  new CopyWebpackPlugin(copyOptions)
);

/*
* STYLESHEETS
*/
environment.loaders.append('styl', {
  test: /\.styl$/,
  loader: 'css-loader!stylus-loader?paths=node_modules/bootstrap-stylus/stylus/'
});

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

config.entryStyleSheets.forEach(function (sheetName) {
  environment.entry[`stylesheet-${sheetName}`] = `./${config.sourcePath}/${config.stylesheetsDirectory}/${sheetName}.styl`;
});

// pre and post build scripts to run
environment.plugins.append(
  'WebpackShell',
  new WebpackShellPlugin({
    onBuildStart: onBuildStart,
    onBuildEnd: []
  })
);

module.exports = environment;
