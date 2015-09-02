#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"
exec      = require("child_process").exec


#--------------------------------------------------------
# Run the rake task to generate the i18n js files
#--------------------------------------------------------

gulp.task "i18n", (cb) ->
  exec "bundle exec rake i18n:js:export", (err, stdout, stderr) ->
    if stdout
      console.log stdout
    if stderr
      console.log stderr
    cb err
