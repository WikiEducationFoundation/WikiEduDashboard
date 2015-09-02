#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp           = require 'gulp'
mainBowerFiles = require 'main-bower-files'
plugins        = require('gulp-load-plugins')()
config         = require "../config.coffee"


#--------------------------------------------------------
# Concatenate Bower libraries
#--------------------------------------------------------

gulp.task "bower", ->
  return gulp.src mainBowerFiles()
    .pipe plugins.concat("vendor.js")
    .pipe gulp.dest "#{config.outputPath}/#{config.jsDirectory}"
