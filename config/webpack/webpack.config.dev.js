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
        main: hotEntry(source + "main.coffee"),
        survey: hotEntry(source + "surveys/survey.coffee"),
        survey_admin: hotEntry(source + "surveys/survey-admin.coffee")
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
        loaders: [
            { 
                test: /\.jsx?$/, 
                exclude: [/vendor/, /node_modules/],
                loaders:['babel'] 
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
        "jquery": "$",
        "i18n-js": 'I18n'
    },
    plugins: [
        new webpack.HotModuleReplacementPlugin()
    ],
    coffeelint: {
        configFile: __dirname + "/coffeelint.json"
    }
};