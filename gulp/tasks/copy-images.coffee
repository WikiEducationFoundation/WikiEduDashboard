#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Copy images
#--------------------------------------------------------

gulp.task "copy-images", ->
  
  gulp.src "#{config.sourcePath}/#{config.imagesDirectory}/**/*"
    .pipe plugins.plumber()
    .pipe plugins.newer("#{config.outputPath}/#{config.imagesDirectory}")
    .pipe plugins.imagemin
      optimizationLevel: 5
    .pipe gulp.dest "#{config.outputPath}/#{config.imagesDirectory}"