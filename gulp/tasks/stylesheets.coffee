#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp    = require 'gulp'
plugins = require('gulp-load-plugins')()
config  = require "../config.coffee"
flipper = require "gulp-css-flipper"

#--------------------------------------------------------
# Compile Stylesheets
#--------------------------------------------------------

gulp.task "stylesheets", ->
  gulp.src ["#{config.sourcePath}/#{config.cssDirectory}/#{config.cssMainFile}.styl"]
    .pipe plugins.plumber()
    .pipe plugins.stylus
      sourcemap:
        inline: config.development
    .pipe plugins.sourcemaps.init
      loadMaps: true
    .pipe plugins.autoprefixer()
    .pipe plugins.sourcemaps.write()
    .pipe gulp.dest "#{config.outputPath}/#{config.cssDirectory}"

  gulp.src ["#{config.sourcePath}/#{config.cssDirectory}/ie.styl"]
    .pipe plugins.plumber()
    .pipe plugins.stylus()
    .pipe plugins.autoprefixer()
    .pipe gulp.dest "#{config.outputPath}/#{config.cssDirectory}"

  # Flip for RTL
  gulp.src "#{config.outputPath}/#{config.cssDirectory}/*.css"
    .pipe flipper()
    .pipe gulp.dest "#{config.outputPath}/#{config.cssDirectory}/rtl"
