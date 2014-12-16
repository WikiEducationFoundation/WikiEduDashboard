#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"
merge     = require 'merge-stream'


#--------------------------------------------------------
# Minify 
#--------------------------------------------------------

gulp.task "minify", ->

  # Compress Main JavaScript
  js = gulp.src "#{config.outputPath}/#{config.jsDirectory}/#{config.jsMainFile}.js"
    .pipe plugins.uglify()
    .pipe gulp.dest "#{config.outputPath}/#{config.jsDirectory}/"

  # Compress Vendor JavaScript
  vendor = gulp.src "#{config.outputPath}/#{config.jsDirectory}/vendor.js"
    .pipe plugins.uglify()
    .pipe gulp.dest "#{config.outputPath}/#{config.jsDirectory}/"

  # Minify CSS
  css = gulp.src "#{config.outputPath}/#{config.cssDirectory}/*.css"
    .pipe plugins.minifyCss()
    .pipe gulp.dest "#{config.outputPath}/#{config.cssDirectory}"

  return merge(js, vendor, css)