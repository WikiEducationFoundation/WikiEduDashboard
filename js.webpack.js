const path = require('path');
const config = require('./config');
const LodashModuleReplacementPlugin = require('lodash-webpack-plugin');
const ESLintPlugin = require('eslint-webpack-plugin');
const MomentLocalesPlugin = require('moment-locales-webpack-plugin');

const jsSource = `./${config.sourcePath}/${config.jsDirectory}`;
const appRoot = path.resolve('./');

const entry = {
  main: [`${jsSource}/main.js`],
  sentry: [`${jsSource}/sentry.js`],
  styleguide: [`${jsSource}/styleguide/styleguide.jsx`],
  survey: [`${jsSource}/surveys/survey.js`],
  survey_admin: [`${jsSource}/surveys/survey-admin.js`],
  survey_results: [`${jsSource}/surveys/survey-results.jsx`],
  campaigns: [`${jsSource}/campaigns.js`],
  charts: [`${jsSource}/charts.js`],
  tinymce: [`${jsSource}/tinymce.js`],
  embed_course_stats: [`${jsSource}/embed_course_stats.js`],
  accordian: [`${jsSource}/accordian.js`]
};

module.exports = (env) => {
  const outputPath = path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`);

  let devtool;
  // see https://webpack.js.org/configuration/devtool/ for the detailed descriptions of these
  if (env.production) {
    devtool = 'source-map';
  } else if (env.coverage) {
    devtool = 'cheap-module-source-map';
  } else {
    devtool = 'eval-cheap-source-map';
  }

  if (env.coverage) {
    // In coverage mode, every React component should
    // be bundled within main.js
    entry.main = [`${jsSource}/main-coverage.js`];
  }

  return {
    entry,
    output: {
      path: outputPath,
      filename: env.development ? '[name].js' : '[name].[chunkhash].js',
      publicPath: '/assets/javascripts/',
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
      ],
    },
    externals: {
      jquery: 'jQuery',
      'i18n-js': 'I18n'
    },
    plugins: [
      // Creates smaller Lodash builds by replacing feature sets of modules with noop,
      // identity, or simpler alternatives.
      new LodashModuleReplacementPlugin(config.requiredLodashFeatures),
      new MomentLocalesPlugin(),
      new ESLintPlugin({
        files: 'app/assets/javascripts/**/*.{js,jsx}',
        failOnError: !!env.production,
        threads: true,
        lintDirtyModulesOnly: true,
        cache: true
      }),
    ],
    optimization: {
      splitChunks: {
        cacheGroups: {
          defaultVendors: {
            test: /[\\/]node_modules[\\/]((?!(chart)).*)[\\/]/,
            chunks: chunk => !/tinymce/.test(chunk.name),
            name: 'vendors'
          }
        }
      },
    },
    devtool,
    stats: env.stats ? 'normal' : 'minimal',
  };
};

