#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp    = require 'gulp'
plugins = require('gulp-load-plugins')()
config  = require "../config.coffee"

# --------------------------------------------------------
# Run server
# --------------------------------------------------------

gulp.task "server", ->
   gulp.src "public"
    .pipe plugins.webserver
      port: 3000
      livereload: true 