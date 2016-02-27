var webpack = require('webpack');

module.exports = {

    entry: {
        survey: "./app/assets/javascripts/survey.coffee",
        survey_admin: "./app/assets/javascripts/survey-admin.coffee",
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