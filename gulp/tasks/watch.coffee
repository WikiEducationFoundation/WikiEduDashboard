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

  plugins.watch "#{config.sourcePath}/#{config.jsDirectory}/**/*.{coffee,js}", ->
    gulp.start "javascripts"

  plugins.watch "bower.json", ->
    gulp.start "bower"

  # server = plugins.livereload()
  # plugins.livereload.listen()

  # plugins.watch "#{config.publicPath}/**/*.{css,js,svg,jpg,gif,png}"
  #   .pipe plugins.livereload()

  return