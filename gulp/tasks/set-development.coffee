#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp   = require 'gulp'
config = require "../config.coffee"

#--------------------------------------------------------

gulp.task "set-development", ->
  config.development = true