#--------------------------------------------------------
# Requirements
#--------------------------------------------------------

gulp      = require 'gulp'
plugins   = require('gulp-load-plugins')()

#--------------------------------------------------------
# Coverage
#--------------------------------------------------------

gulp.task("js_coverage", require('gulp-jsx-coverage').createTask(
  src: [
    'test/components/**/*.coffee',

    'app/assets/javascripts/*.coffee',
    'app/assets/javascripts/utils/*.coffee',

    'app/assets/javascripts/components/*.cjsx',
    'app/assets/javascripts/components/**/*.cjsx',

    'app/assets/javascripts/stores/*.coffee',
    'app/assets/javascripts/actions/*.coffee',

    'app/assets/javascripts/training/components/*.cjsx',
    'app/assets/javascripts/training/actions/*.coffee',
    'app/assets/javascripts/training/stores/*.coffee',
  ]
  isparta: false
  istanbul:
    preserveComments: true
    coverageVariable: '__MY_TEST_COVERAGE__',
    exclude: /node_modules|test[0-9]/
  transpile:
    cjsx:
      include: /\.cjsx$/
      omitExt: ['.cjsx']
  coverage:
    reporters: ['text-summary', 'json', 'lcov']
    directory: 'js_coverage'
  mocha:
    reporter: 'spec'
  coffee:
    sourceMap: true
))
