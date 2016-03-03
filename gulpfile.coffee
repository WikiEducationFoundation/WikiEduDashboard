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

# Require individual tasks
requireDir './gulp/tasks', { recurse: true }

#---------------------------------------------------------

gulp.task "default", ["dev"]

gulp.task "dev", ->
  runSequence "clean", "set-development", [
    "i18n"
    "copy-static"
    "bower"
    "javascripts"
    "stylesheets"
  ], "watch"

gulp.task "build", (cb) ->
  runSequence "clean", [
    "i18n"
    "copy-static"
    "bower"
    "javascripts-fingerprint"
    "stylesheets"
  ], "minify", cb

