#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"
coffeeify = require 'coffeeify'
handleify = require 'handleify'
reactify  = require 'reactify'
revDel  = require 'rev-del'
utils   = require '../utils.coffee'


#--------------------------------------------------------
# Compile JavaScripts
#--------------------------------------------------------

gulp.task "javascripts", ->
  js_dir = "#{config.outputPath}/#{config.jsDirectory}"
  utils.update_manifest(js_dir, "#{config.jsMainFile}.js")
  gulp.src "#{config.sourcePath}/#{config.jsDirectory}/#{config.jsMainFile}.coffee", read: false
    .pipe plugins.plumber()
    .pipe plugins.browserify
      transform:  ["handleify", "reactify", "coffee-reactify"]
      extensions: [".coffee", ".js", ".jsx", ".cjsx"]
      debug: config.development
    .pipe plugins.rename "#{config.jsMainFile}.js"
    .pipe gulp.dest js_dir

gulp.task "javascripts-fingerprint", ->
  js_dir = "#{config.outputPath}/#{config.jsDirectory}"
  gulp.src "#{config.sourcePath}/#{config.jsDirectory}/#{config.jsMainFile}.coffee", read: false
    .pipe plugins.plumber()
    .pipe plugins.browserify
      transform:  ["handleify", "reactify", "coffee-reactify"]
      extensions: [".coffee", ".js", ".jsx", ".cjsx"]
      debug: config.development
    .pipe plugins.rename "#{config.jsMainFile}.js"
    .pipe plugins.rev()
    .pipe gulp.dest js_dir
    .pipe plugins.rev.manifest()
    .pipe revDel({ dest: js_dir })
    .pipe gulp.dest js_dir
