#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


# --------------------------------------------------------
# Clean output directories
# --------------------------------------------------------

gulp.task "clean", ->
  
  directoriesToClean = [
    "#{config.outputPath}/#{config.jsDirectory}"
    "#{config.outputPath}/#{config.cssDirectory}"
    "#{config.outputPath}/#{config.imagesDirectory}"
  ]

  gulp.src directoriesToClean, read: false
    .pipe plugins.clean()