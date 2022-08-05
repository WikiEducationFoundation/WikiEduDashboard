const path = require('path');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RtlCssPlugin = require('rtlcss-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const ESLintPlugin = require('eslint-webpack-plugin');
const config = require('./config');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
const cssSource = `./${config.sourcePath}/${config.cssDirectory}`;
const outputPath = path.resolve(`${config.outputPath}`);

module.exports = (env) => {
  const mode = env.development ? 'development' : 'production';
  const isProductionOrCI = env.production || env.coverage;
  let devtool = 'eval-cheap-source-map';
  // see https://webpack.js.org/configuration/devtool/ for the detailed descriptions of these
  if (env.production) {
    devtool = 'source-map';
  } else if (env.coverage) {
    devtool = 'cheap-module-source-map';
  }

  const entries = {
    main: [`${jsSource}/main.js`, `${cssSource}/main.styl`],
    styleguide: [`${jsSource}/styleguide/styleguide.jsx`, `${cssSource}/styleguide.styl`],

    sentry: [`${jsSource}/sentry.js`],
    survey: [`${jsSource}/surveys/survey.js`],
    survey_admin: [`${jsSource}/surveys/survey-admin.js`],
    survey_results: [`${jsSource}/surveys/survey-results.jsx`],
    campaigns: [`${jsSource}/campaigns.js`],
    charts: [`${jsSource}/charts.js`],
    embed_course_stats: [`${jsSource}/embed_course_stats.js`],
    accordian: [`${jsSource}/accordian.js`],

    surveys: [`${cssSource}/surveys.styl`],
    training: [`${cssSource}/training.styl`],
  };

  const output = {
    mode,
    output: {
      path: outputPath,
      filename: env.development ? 'javascripts/[name].js' : 'javascripts/[name].[chunkhash].js',
      publicPath: '/assets/',
    },
    entry: entries,
    resolve: {
      extensions: ['.js', '.jsx', '.styl'],
      symlinks: false,
      // bug in React 17. Should be removed when we upgrade to React 18
      // See https://github.com/react-dnd/react-dnd/issues/3423#issuecomment-1092621793
      fallback: {
        'react/jsx-runtime': 'react/jsx-runtime.js',
        'react/jsx-dev-runtime': 'react/jsx-dev-runtime.js',
      },
    },

    module: {
      rules: [
        {
          test: /\.jsx?$/,
          include: path.resolve(__dirname, 'app/assets/javascripts'),
          use: {
            loader: require.resolve('babel-loader'),
            options: {
              cacheDirectory: true,
              cacheCompression: false
            },
          },
        },
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
      ],
    },
    plugins: [
      !env.DISABLE_ESLINT && new ESLintPlugin({
        files: 'app/assets/javascripts/**/*.{js,jsx}',
        failOnError: isProductionOrCI,
        threads: isProductionOrCI,
        lintDirtyModulesOnly: !isProductionOrCI,
        cache: !isProductionOrCI
      }),

      new MiniCssExtractPlugin({
        filename: env.development ? 'stylesheets/[name].css' : 'stylesheets/[name].[contenthash].css',
      }),

      // generates a RTL version of the emitted CSS files
      // this is done only in production/coverage
      (env.production || env.coverage) && (new RtlCssPlugin({
        filename: 'stylesheets/rtl-[name].[fullhash].css'
      })),

      new WebpackManifestPlugin({
        fileName: 'javascripts/manifest.json',
        map: (file) => {
          if (/rtl-.*\.css$/.test(file.path)) {
            file.name = `rtl-${file.name}`;
          }
          return file;
        }
      }),
      (env.development && !env.coverage) && new ReactRefreshWebpackPlugin({ overlay: {
        sockPort: 8080
      } }),
      (env.analyze && new BundleAnalyzerPlugin())
    ].filter(Boolean),

    optimization: {
      splitChunks: {
        cacheGroups: {
          defaultVendors: {
            test: /[\\/]node_modules[\\/]((?!(chart|tinymce)).*)[\\/]/,
            chunks: 'all',
            name: 'vendors'
          },
        }
      },
      minimizer: [
        '...',
        new CssMinimizerPlugin(),
      ],
    },
    externals: {
      jquery: 'jQuery',
      'i18n-js': 'I18n'
    },
    devtool,
    stats: env.stats ? 'normal' : 'minimal',
  };

  if (env.development && env.memory) {
    output.devServer = {
      hot: true
    };
  } else if (env.development) {
    output.devServer = {
      devMiddleware: {
        publicPath: path.join(__dirname, '/public'),
        writeToDisk: true,
      },
    };
  }
  return output;
};
