#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Clean
#--------------------------------------------------------

gulp.task "clean", ->

  return gulp.src "#{config.outputPath}", read: false
    .pipe plugins.clean()
