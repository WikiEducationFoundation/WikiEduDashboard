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
  return runSequence "set-development", [
    "copy-static"
    "bower"
    "javascripts"
    "stylesheets"
  ], "watch"

gulp.task "build", ->
  return runSequence "clean", [
    "i18n"
    "copy-static"
    "bower"
    "javascripts-fingerprint"
    "stylesheets-fingerprint"
  ], "minify"

