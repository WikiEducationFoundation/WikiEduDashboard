import gulp from 'gulp';
import jsxCoverage from 'gulp-jsx-coverage';

gulp.task('js_coverage', jsxCoverage.createTask({
  src: [
    'test/components/**/*.coffee',
    'test/main/**/*.coffee',
    'test/utils/**/*.coffee',
    'test/components/**/*.js',
    'test/main/**/*.js',
    'test/utils/**/*.js',
    'test/components/**/*.jsx',
    'test/main/**/*.jsx',
    'test/utils/**/*.jsx',

    'app/assets/javascripts/*.coffee',
    'app/assets/javascripts/utils/*.coffee',
    'app/assets/javascripts/*.js',
    'app/assets/javascripts/utils/*.js',

    'app/assets/javascripts/components/*.cjsx',
    'app/assets/javascripts/components/**/*.cjsx',
    'app/assets/javascripts/components/*.jsx',
    'app/assets/javascripts/components/**/*.jsx',

    'app/assets/javascripts/stores/*.coffee',
    'app/assets/javascripts/actions/*.coffee',
    'app/assets/javascripts/stores/*.js',
    'app/assets/javascripts/actions/*.js',

    'app/assets/javascripts/training/components/*.cjsx',
    'app/assets/javascripts/training/actions/*.coffee',
    'app/assets/javascripts/training/stores/*.coffee',
    'app/assets/javascripts/training/components/*.jsx',
    'app/assets/javascripts/training/actions/*.js',
    'app/assets/javascripts/training/stores/*.js',
  ],
  isparta: false,
  istanbul: {
    preserveComments: true,
    coverageVariable: '__MY_TEST_COVERAGE__',
    exclude: /node_modules|test|public/
  },
  transpile: {
    babel: {
      include: /\.jsx?$/,
    },
    coffee: {
      include: /\.coffee$/
    },
    cjsx: {
      include: /\.cjsx$/
    }
  },
  coverage: {
    reporters: ['text-summary', 'json', 'lcov'],
    directory: 'js_coverage'
  },
  mocha: {
    reporter: 'spec'
  },
  coffee: {
    sourceMap: true
  }
}));
