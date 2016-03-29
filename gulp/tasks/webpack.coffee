#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp             = require 'gulp'
plugins          = require('gulp-load-plugins')()
webpack          = require 'webpack'
WebpackDevServer = require 'webpack-dev-server'


#--------------------------------------------------------
# Compile JavaScripts
#--------------------------------------------------------

# Production Webpack Build with Timestamps and Manifest Generation
gulp.task "webpack-build", ["bower"], plugins.shell.task ["npm run build"]

# Development Webpack Task
gulp.task "webpack-dev", (cb) ->
  config = require("../../config/webpack/webpack.config.dev.js")
  new WebpackDevServer(webpack(config) ,{}).listen(8080, "localhost", (err)->
    throw new plugins.util.PluginError("webpack-dev-server", err) if err
    plugins.util.log "[webpack-dev-server] Running"
  )
  plugins.shell.task ["npm run hotdev"]
  cb()
