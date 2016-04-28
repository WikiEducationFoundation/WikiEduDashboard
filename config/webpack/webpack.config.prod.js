var webpack = require('webpack');
var ManifestPlugin = require('webpack-manifest-plugin');
var source = __dirname + "/../../app/assets/javascripts/";
var output = "./public/assets/javascripts";

module.exports = {
    entry: {
        main : source + "main.js",
        survey: source + "surveys/survey.js",
        survey_admin: source + "surveys/survey-admin.coffee",
        survey_results: source + "surveys/survey-results.js"
    },
    output: {
        path: output,
        filename: "[name].[hash].js",
    },
    resolve: {
        extension: ['', '.js', '.jsx', '.coffee', '.cjsx'],
        root: [__dirname + "vendor", __dirname + "node_modules"]
    },
    module: {
        loaders: [
            {
                test: /\.jsx?$/,
                exclude: [/vendor/, /node_modules/],
                loader: 'babel',
                query: {
                    cacheDirectory: true
                }
            },
            {
                test: /\.cjsx$/,
                loaders: ['coffee', 'cjsx']
            },
            {
                test: /\.coffee$/,
                loaders: ["coffee-loader"]
            },
            {
                test: /\.json$/,
                loader: "json-loader"
            }
        ]
    },
     externals: {
        "jquery": "jQuery",
        "jquery": "$",
        "i18n-js": 'I18n'
    },

    plugins: [
      new ManifestPlugin({
        fileName: 'rev-manifest.json'
      }),
      new webpack.DefinePlugin({
        'process.env': {
          'NODE_ENV': JSON.stringify("production")
        }
      })
    ]
};
