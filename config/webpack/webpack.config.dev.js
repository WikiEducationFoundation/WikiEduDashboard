var webpack = require('webpack');
var source = __dirname + "/../../app/assets/javascripts/";

module.exports = {
  entry: {
    main: hotEntry(source + "main.js"),
    survey: hotEntry(source + "surveys/survey.js"),
    survey_admin: hotEntry(source + "surveys/survey-admin.coffee"),
    survey_results: hotEntry(source + "surveys/survey-results.js")
  },
  output: {
    path: __dirname + "/",
    filename: "[name].js",
    publicPath: '/'
  },
  resolve: {
    extension: ['', '.js', '.jsx', '.coffee', '.cjsx'],
    root: [__dirname + "vendor", __dirname + "node_modules"]
  },
  module: {
    loaders: [{
      test: /\.jsx?$/,
      exclude: [/vendor/, /node_modules/],
      loader: 'babel',
      query: {
        cacheDirectory: true
      }
    }, {
      test: /\.coffee$/,
      loaders: ["coffee-loader"]
    }, {
      test: /\.cjsx$/,
      loaders: ['coffee', 'cjsx']
    }, , {
      test: /\.json$/,
      loader: "json-loader"
    }]
  },
  externals: {
    "jquery": "jQuery",
    "jquery": "$",
    "i18n-js": 'I18n'
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin()
  ],
  devtool: 'inline-source-map'
};



function hotEntry(entry) {
  return [
    'webpack-dev-server/client?http://localhost:8080',
    'webpack/hot/only-dev-server',
    entry
  ]
}
