#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp    = require 'gulp'
plugins = require('gulp-load-plugins')()
config  = require "../config.coffee"
flipper = require "gulp-css-flipper"
revDel  = require 'rev-del'
utils   = require '../utils.coffee'

#--------------------------------------------------------
# Compile Stylesheets
#--------------------------------------------------------

gulp.task "stylesheets", ->
  style_dir = "#{config.outputPath}/#{config.cssDirectory}"
  utils.update_manifest(style_dir, "#{config.cssMainFiles}.css")

  stream = gulp.src ["#{config.sourcePath}/#{config.cssDirectory}/#{config.cssMainFiles}.styl"]
    .pipe plugins.plumber()
    .pipe plugins.stylus
      sourcemap:
        inline: config.development
    .pipe plugins.sourcemaps.init
      loadMaps: true
    .pipe plugins.autoprefixer()
    .pipe plugins.sourcemaps.write()
    .pipe gulp.dest style_dir

  stream.on 'end', =>
    # Flip for RTL
    rtl_dir = "#{config.outputPath}/#{config.cssDirectory}/rtl"
    utils.update_manifest(rtl_dir, "#{config.cssMainFiles}.css")
    gulp.src "#{config.outputPath}/#{config.cssDirectory}/*.css"
      .pipe flipper()
      .pipe gulp.dest rtl_dir

gulp.task "stylesheets-fingerprint", ->
  style_dir = "#{config.outputPath}/#{config.cssDirectory}"
  stream = gulp.src ["#{config.sourcePath}/#{config.cssDirectory}/#{config.cssMainFiles}.styl"]
    .pipe plugins.plumber()
    .pipe plugins.stylus
      sourcemap:
        inline: config.development
    .pipe plugins.sourcemaps.init
      loadMaps: true
    .pipe plugins.autoprefixer()
    .pipe plugins.sourcemaps.write()
    .pipe gulp.dest style_dir

  stream.on 'end', =>
    # Flip for RTL
    rtl_dir = "#{config.outputPath}/#{config.cssDirectory}/rtl"
    rtl_stream = gulp.src ["#{config.outputPath}/#{config.cssDirectory}/#{config.cssMainFiles}.css"]
      .pipe flipper()
      .pipe plugins.rev()
      .pipe gulp.dest rtl_dir
      .pipe plugins.rev.manifest()
      .pipe revDel({ dest: rtl_dir })
      .pipe gulp.dest rtl_dir

    rtl_stream.on 'end', =>
      gulp.src ["#{config.outputPath}/#{config.cssDirectory}/#{config.cssMainFiles}.css"]
        .pipe plugins.rev()
        .pipe gulp.dest style_dir
        .pipe plugins.rev.manifest()
        .pipe revDel({ dest: style_dir })
        .pipe gulp.dest style_dir
