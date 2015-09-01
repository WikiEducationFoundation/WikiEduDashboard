#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Copy images, misc public files, and fonts
#--------------------------------------------------------

gulp.task "i18n", ->
  return plugins.run('rake i18n:js:export').exec()
