import gulp from 'gulp';
import requireDir from 'require-dir';
import runSequence from 'run-sequence';

// Require individual tasks
requireDir('./gulp/tasks', { recurse: true });

gulp.task('default', ['dev']);

gulp.task('dev', () =>
  runSequence('clean', 'set-development', [
    'i18n',
    'copy-static',
    'bower',
    'stylesheets-livereload',
    'cached-lintjs-watch'
  ], 'webpack-dev', 'watch')
);

gulp.task('build', cb =>
  runSequence('clean', [
    'i18n',
    'copy-static',
    'bower',
    'stylesheets',
    'lintjs'
  ], 'webpack-build', 'minify', cb)
);
