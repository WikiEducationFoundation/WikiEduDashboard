#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()
config    = require "../config.coffee"


#--------------------------------------------------------
# Icon Font
#--------------------------------------------------------

gulp.task "icon-font", ->

  cssTemplateFilename = "icon-font-template.css"
  cssOutputFilename = "_icons.styl"
  fontName = "icons"
  fontPath = "../fonts/"
  className = "icon"

  # Grab SVGs from 'svg' directory
  fileSvgStream = gulp.src "#{config.sourcePath}/#{config.svgDirectory}/*.svg"

  # Generate Font and CSS from all SVGs
  fileSvgStream
    .pipe(plugins.iconfont
      fontName: "icons"
      normalize: true
    ).on("codepoints", (codepoints, options) ->
      gulp.src "#{config.sourcePath}/#{config.svgDirectory}/#{cssTemplateFilename}"
        .pipe(plugins.consolidate "lodash",
          glyphs: codepoints
          fontName: fontName
          fontPath: fontPath
          className: className
        ).pipe plugins.rename cssOutputFilename
        .pipe gulp.dest "#{config.sourcePath}/#{config.cssDirectory}"
    ).pipe gulp.dest "#{config.outputPath}/#{config.fontsDirectory}"