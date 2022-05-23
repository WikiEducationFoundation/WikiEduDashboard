const config = require('./config');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RtlCssPlugin = require('rtlcss-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');

const cssSource = `./${config.sourcePath}/${config.cssDirectory}`;

const entry = {
  main: [`${cssSource}/main.styl`],
  styleguide: [`${cssSource}/styleguide.styl`],
  surveys: [`${cssSource}/surveys.styl`],
  training: [`${cssSource}/training.styl`],
};

module.exports = (env) => {
  const mode = env.development ? 'development' : 'production';
  return {
    mode,
    entry,
    module: {
      rules: [
        {
          test: /\.styl$/,
          use: [
            MiniCssExtractPlugin.loader,
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
          // this inlines resources if they are less than 8KB
          test: /\.(png|jpe?g|gif|svg|eot|ttf|woff|woff2)$/i,
          type: 'asset'
        }
      ]
    },
    plugins: [
      // extracts CSS to a separate file
      new MiniCssExtractPlugin({
        filename: env.development ? '../stylesheets/[name].css' : '../stylesheets/[name].[contenthash].css',
      }),
      // generates a RTL version of the emitted CSS files
      // this is done only in production/coverage
      ...(env.production || env.coverage ? [new RtlCssPlugin({
        filename: '../stylesheets/rtl-[name].[fullhash].css'
      })] : []),
    ],
    optimization: {
      minimizer: [
        '...',
        new CssMinimizerPlugin(),
      ],
    },
    stats: 'minimal',
  };
};
