var webpack = require('webpack');
var source = __dirname + "/../../app/assets/javascripts/";

module.exports = {

    entry: {
        main : source + "surveys/main.coffee",
        survey: source + "surveys/survey.coffee",
    },
    output: {
        filename: "[name].js",
        publicPath: '/static/'
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