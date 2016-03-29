var webpack = require('webpack');
var source = __dirname + "/../../app/assets/javascripts/";



module.exports = {
    entry: {
        main: hotEntry(source + "main.js"),
        survey: hotEntry(source + "surveys/survey.coffee"),
        survey_admin: hotEntry(source + "surveys/survey-admin.coffee")
    },
    output: {
        path: __dirname + "/",
        filename: "[name].js",
        publicPath: '/'
    },
    resolve: {
        extension: ['', '.js', '.jsx', '.coffee'],
        root: ["vendor", "node_modules"]
    },
    module: {
        preLoaders: [
            {
                test: /\.coffee$/,
                loader:"coffee-lint-loader",
                exclude: [/vendor/, /node_modules/]
            }
        ],
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
                test: /\.coffee$/,
                loaders: ["coffee-loader"]
            },
            {
                test: /\.cjsx$/,
                loaders: ['coffee', 'cjsx']
            },
            ,
            {   test: /\.json$/,
                loader: "json-loader"
            }
        ]
    },
     externals: {
        "jquery": "jQuery",
        "jquery": "$"
    },
    plugins: [
        new webpack.HotModuleReplacementPlugin()
    ],
    coffeelint: {
        configFile: __dirname + "/coffeelint.json"
    },
    devtool: 'inline-source-map'
};



function hotEntry(entry) {
    return [
        'webpack-dev-server/client?http://localhost:8080',
        'webpack/hot/only-dev-server',
        entry
    ]
}
