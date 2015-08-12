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
  runSequence "set-development", [
    "copy-images"
    "bower"
    "javascripts"
    "stylesheets"
  ], "watch"

gulp.task "build", ->
  runSequence [
    "copy-images"
    "bower"
    "javascripts-fingerprint"
    "stylesheets-fingerprint"
  ], "minify"

