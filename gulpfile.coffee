#########################################################
# WINTR Gulp Config
# Author: matt@wintr.us and team @ WINTR
#########################################################

#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp           = require 'gulp'
requireDir     = require 'require-dir'
runSequence    = require 'run-sequence'
plugins         = require('gulp-load-plugins')()

# Require individual tasks
requireDir './gulp/tasks', { recurse: true }

#---------------------------------------------------------

gulp.task "default", ["dev"]

gulp.task "dev", ->
  runSequence "clean", "set-development", [
    "i18n"
    "copy-static"
    "bower"
    "webpack-hotdev"
    "javascripts"
    "stylesheets"
  ], "watch"

gulp.task "webpack-build", ["bower"], plugins.shell.task ["npm run build"]
gulp.task "webpack-hotdev", plugins.shell.task ["npm run hotdev"]

gulp.task "build", (cb) ->
  runSequence "clean",
    "i18n",
    "copy-static",
    "bower",
    "stylesheets-fingerprint",
    "webpack-build", "minify", cb

