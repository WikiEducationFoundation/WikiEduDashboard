#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Lint
#--------------------------------------------------------

gulp.task "lintjs", ->

  gulp.src "#{config.sourcePath}/#{config.jsDirectory}/**/*.{jsx,js}"
    .pipe(plugins.eslint())
    .pipe(plugins.eslint.format())
    .pipe(plugins.eslint.failAfterError());
