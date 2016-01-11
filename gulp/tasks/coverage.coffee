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
    'test/components/training/slide_link_test.coffee'
  ]
  isparta: false
  istanbul:
    preserveComments: true
    coverageVariable: '__MY_TEST_COVERAGE__',
    exclude: /node_modules|test[0-9]/
  transpile:
    cjsx: /\.cjsx$/
    omitExt: ['.cjsx']
  coverage:
    reporters: ['text-summary', 'json', 'lcov']
    directory: 'js_coverage'
  mocha:
    reporter: 'spec'
  coffee:
    sourceMap: true
))
