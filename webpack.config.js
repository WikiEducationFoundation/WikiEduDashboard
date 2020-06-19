const path = require('path');
const webpack = require('webpack');

module.exports = (env) => {
  const jsConfig = require('./js.webpack')(env);
  const cssConfig = require('./css.webpack')(env);
  const doHot = env.development && !env.watch_js;
  const entries = {
    ...jsConfig.entry,
    ...cssConfig.entry,
    main: [...jsConfig.entry.main, ...cssConfig.entry.main],
    styleguide: [...jsConfig.entry.styleguide, ...cssConfig.entry.styleguide]
  };

  if (doHot) {
    // wrap entries with hot hooks
    Object.keys(entries).forEach((key) => {
      entries[key] = [
        'webpack-dev-server/client?http://localhost:8080',
        'webpack/hot/only-dev-server',
      ].concat(entries[key]);
    });
  }

  return {
    ...jsConfig,
    entry: entries,
    resolve: {
      extensions: ['.js', '.jsx', '.styl'],
      symlinks: false
    },
    module: {
      rules: [...jsConfig.module.rules, ...cssConfig.module.rules],
    },
    devServer: {
      port: 8080,
      contentBase: path.join(__dirname, 'public'),
      writeToDisk: true,
    },
    plugins: [...cssConfig.plugins, ...jsConfig.plugins, ...(doHot ? [new webpack.HotModuleReplacementPlugin()] : [])],
  };
};
