#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Watch for changes and reload
#--------------------------------------------------------

gulp.task "watch", ->

  plugins.watch "#{config.sourcePath}/#{config.cssDirectory}/**/*.{styl,sass,scss,css}", ->
    gulp.start "stylesheets"

  plugins.watch "#{config.sourcePath}/#{config.imagesDirectory}/**/*", ->
    gulp.start "copy-images"

  plugins.watch "bower.json", ->
    gulp.start "bower"

  plugins.livereload.listen()
  gulp.watch "#{config.outputPath}/#{config.cssDirectory}/*.css", (e) ->
    plugins.livereload.changed(e.path)

  return
