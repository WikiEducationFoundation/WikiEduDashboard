const path = require('path');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');

module.exports = (env) => {
  const jsConfig = require('./js.webpack')(env);
  const cssConfig = require('./css.webpack')(env);
  const mode = env.development ? 'development' : 'production';
  const entries = {
    ...jsConfig.entry,
    ...cssConfig.entry,
    main: [...jsConfig.entry.main, ...cssConfig.entry.main],
    styleguide: [...jsConfig.entry.styleguide, ...cssConfig.entry.styleguide]
  };
  const output = {
    ...jsConfig,
    mode,
    entry: entries,
    resolve: {
      extensions: ['.js', '.jsx', '.styl'],
      symlinks: false
    },
    module: {
      rules: [...jsConfig.module.rules, ...cssConfig.module.rules],
    },

    plugins: [
      ...cssConfig.plugins,
      ...jsConfig.plugins,
      new WebpackManifestPlugin({
        fileName: 'manifest.json',
        map: (file) => {
          if (/rtl-.*\.css$/.test(file.path)) {
            file.name = `rtl-${file.name}`;
          }
          return file;
        }
      })
    ],
  };
  if (env.development) {
    output.devServer = {
      devMiddleware: {
        publicPath: path.join(__dirname, '/public'),
        writeToDisk: true,
      },
    };
  }
  return output;
};
