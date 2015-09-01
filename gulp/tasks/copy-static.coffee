#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"
runSequence = require "run-sequence"


#--------------------------------------------------------
# Copy images, misc public files, and fonts
#--------------------------------------------------------

gulp.task "copy-images", ->

  return gulp.src "#{config.sourcePath}/#{config.imagesDirectory}/**/*"
    .pipe plugins.plumber()
    .pipe plugins.newer("#{config.outputPath}/#{config.imagesDirectory}")
    .pipe plugins.imagemin
      optimizationLevel: 5
    .pipe gulp.dest "#{config.outputPath}/#{config.imagesDirectory}"


gulp.task "copy-misc", ->

  return gulp.src "#{config.sourcePath}/*.*"
    .pipe gulp.dest "#{config.outputPath}"

gulp.task "copy-fonts", ->

  return gulp.src "#{config.sourcePath}/#{config.fontsDirectory}/**/*"
    .pipe gulp.dest "#{config.outputPath}/#{config.fontsDirectory}"


gulp.task "copy-static", (cb) ->
  runSequence ["copy-images", "copy-misc", "copy-fonts"], cb
