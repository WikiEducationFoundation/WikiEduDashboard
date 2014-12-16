#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Tests
#--------------------------------------------------------

gulp.task "test", ->
  gulp.start "javascripts"
  
  gulp.src "#{config.testPath}/spec-runner.coffee", read: false
    .pipe plugins.plumber()
    .pipe plugins.browserify
      transform:  ["handleify", "coffeeify"]
      extensions: [".coffee", ".js"]
      debug: true
    .pipe plugins.rename "spec.js"
    .pipe gulp.dest "#{config.testPath}/html"

  gulp.src "#{config.testPath}/html/index.html"
    .pipe plugins.mochaPhantomjs()
