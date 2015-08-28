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
      fontName: fontName
      normalize: true
    ).on("glyphs", (glyphs) ->
      glyphs = glyphs.map((glyph) ->
        name: glyph.name,
        codepoint: glyph.unicode[0].charCodeAt(0)
      )
      gulp.src "#{config.sourcePath}/#{config.svgDirectory}/#{cssTemplateFilename}"
        .pipe(plugins.consolidate "lodash",
          glyphs: glyphs
          fontName: fontName
          fontPath: fontPath
          className: className
        )
        .pipe plugins.rename cssOutputFilename
        .pipe gulp.dest "#{config.sourcePath}/#{config.cssDirectory}"
    ).pipe gulp.dest "#{config.outputPath}/#{config.fontsDirectory}"
