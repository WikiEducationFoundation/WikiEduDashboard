const config = require('./config')
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin')
const WebpackShellPlugin = require('webpack-shell-plugin');

module.exports = {
  entry: {
    js: './src/client.js',
    css: './src/css/main.scss',
  },

  
}