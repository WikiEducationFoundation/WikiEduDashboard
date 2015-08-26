#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp            = require 'gulp'
plugins         = require('gulp-load-plugins')()
config          = require "../config.coffee"
source          = require 'vinyl-source-stream'
buffer          = require 'vinyl-buffer'
revDel          = require 'rev-del'
lodash          = require 'lodash'
utils           = require '../utils.coffee'
browserify      = require 'browserify'
watchify        = require 'watchify'
reactify        = require 'reactify'
uglifyify       = require 'uglifyify'
envify          = require 'envify/custom'
coffeeReactify  = require 'coffee-reactify'


#--------------------------------------------------------
# Compile JavaScripts
#--------------------------------------------------------

outputPath = "#{config.outputPath}/#{config.jsDirectory}"
sourcePath = "#{config.sourcePath}/#{config.jsDirectory}"


# Setup browserify bundler
initBrowserify = -> 
  browserifyOpts =
    extensions: [".coffee", ".js", ".jsx", ".cjsx"]
    entries: ["#{sourcePath}/#{config.jsMainFile}.coffee"]
    debug: true

  b = browserify lodash.assign({}, watchify.args, browserifyOpts)
  b.on 'log', plugins.util.log
  b.transform reactify
  b.transform coffeeReactify

  if config.development
    # use watchify if we're in development mode
    b = watchify b
    b.on 'update', bundle.bind(null, b)
  else
    # uglify and compile react with prod NODE_ENV
    b.transform global: true, uglifyify
    b.transform [envify(_: 'purge', NODE_ENV: 'production'), global: true]

  return b

# Perform bundling
bundle = (b) ->
  b.bundle()
    .on 'error', plugins.util.log.bind(plugins.util, 'Browserify Error')
    .pipe source("#{config.jsMainFile}.js")
    .pipe buffer()
    .pipe plugins.sourcemaps.init(loadMaps: true)
    .pipe if config.development then plugins.util.noop() else plugins.rev() # revs for sourcemap pathing
    .pipe plugins.sourcemaps.write('.')
    .pipe gulp.dest outputPath

gulp.task "javascripts", ->
  utils.update_manifest outputPath, "#{config.jsMainFile}.js"
  bundle initBrowserify()

gulp.task "javascripts-fingerprint", ->
  bundle initBrowserify()
    .pipe gulp.dest outputPath
    .pipe plugins.rev.manifest()
    .pipe revDel(dest: outputPath)
    .pipe gulp.dest outputPath
