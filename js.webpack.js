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
  const doHot = env.development && !env.watch_js;
  const outputPath = doHot
    ? path.resolve(appRoot, `${config.outputPath}/${config.jsDirectory}`)
    : path.resolve(`${config.outputPath}/${config.jsDirectory}`);

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
      filename: doHot ? '[name].js' : '[name].[chunkhash].js',
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
        extensions: ['js', 'jsx'],
        exclude: ['vendor', 'node_modules'],
        cache: true,
        failOnError: !!env.production,
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
    watch: env.watch_js,
    // eval causes trouble with instrumenting and outputs the transformed code which is not useful with coverage data
    // cheap-module-source-map outputs an almost original code at the best possible speed which helps in evaluating the coverage data
    devtool,
    stats: env.stats ? 'normal' : 'minimal',
  };
};

