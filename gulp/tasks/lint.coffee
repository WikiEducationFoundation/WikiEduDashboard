#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
config    = require "../config.coffee"


#--------------------------------------------------------
# Lint
#--------------------------------------------------------

jsPath = "#{config.sourcePath}/#{config.jsDirectory}/**/*.{jsx,js}"

gulp = require('gulp')
path = require('path')
plugins = require('gulp-load-plugins')()

gulp.task('lintjs-watch', () =>
  # Lint only files that change after this watch starts
  lintAndPrint = plugins.eslint()
  # format results with each file, since this stream won't end.
  lintAndPrint.pipe(plugins.eslint.formatEach())

  return gulp.watch(jsPath, (event) =>
    if (event.type != 'deleted')
      gulp.src(event.path)
        .pipe(lintAndPrint, {end: false})
  )
)



gulp.task('cached-lintjs', () =>
  # Read all js files within test/fixtures
  return gulp.src(jsPath)
    .pipe(plugins.cached('eslint'))
    # Only uncached and changed files past this point
    .pipe(plugins.eslint())
    .pipe(plugins.eslint.format())
    .pipe(plugins.eslint.result((result) =>
      if result.warningCount > 0 || result.errorCount > 0
        delete plugins.cached.caches.eslint[path.resolve(result.filePath)]
    ))
)

# Run the "cached-lint" task initially...
gulp.task('cached-lintjs-watch', ['cached-lintjs'], () =>
  # ...and whenever a watched file changes
  return gulp.watch(jsPath, ['cached-lintjs'], (event) =>
    if (event.type == 'deleted' && plugins.cached.caches.eslint)
      # remove deleted files from cache
      delete plugins.cached.caches.eslint[event.path]
  )
)
