var webpack = require('webpack');
var source = __dirname + "/../../app/assets/javascripts/";

function hotEntry(entry) {
    return [
        'webpack-dev-server/client?http://localhost:8080',
        'webpack/hot/only-dev-server',
        entry
    ]
}

module.exports = {
    entry: {
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
        loaders: [
            { 
                test: /\.jsx?$/, 
                exclude: [/vendor/, /node_modules/],
                loaders:['babel'] 
            },
            {
                test: /\.coffee$/,
                loaders: ["coffee-loader"]
            }
        ]
    },
     externals: {
        "jquery": "jQuery",
        "jquery": "$"
    },
    plugins: [
        new webpack.HotModuleReplacementPlugin()
    ]
};