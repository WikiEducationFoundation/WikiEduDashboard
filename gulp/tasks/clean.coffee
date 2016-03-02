#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"
del       = require "del"


#--------------------------------------------------------
# Clean
#--------------------------------------------------------

gulp.task "clean", ->
  return del([
      "#{config.outputPath}/fonts/*", 
      "#{config.outputPath}/images/*", 
      "#{config.outputPath}/stylesheets/*", 
      "#{config.outputPath}/javascripts/*", 
      "!#{config.outputPath}/javascripts/vendor.js"
    ])
