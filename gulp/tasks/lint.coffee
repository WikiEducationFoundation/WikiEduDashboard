#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Lint
#--------------------------------------------------------
    
gulp.task "lint", ->
  
  gulp.src "#{config.sourcePath}/#{config.jsDirectory}/**/*.coffee"
    .pipe plugins.coffeelint()
    .pipe plugins.coffeelint.reporter()
  
  gulp.src "#{config.outputPath}/#{config.cssDirectory}/#{config.cssMainFile}.css"
    .pipe plugins.csslint()
    .pipe plugins.csslint.reporter()
  
  gulp.src("#{config.publicPath}/**/*.html")
    .pipe(plugins.htmlhint("id-class-value": "dash"))
    .pipe plugins.htmlhint.reporter()
