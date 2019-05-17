import gulp from 'gulp';
import requireDir from 'require-dir';

// Require individual tasks
requireDir('./gulp/tasks', { recurse: true });

const { series, parallel } = gulp;
gulp.task('dev',
  series(
    'clean',
    'set-development',
    'set-watch-js',
    parallel('i18n', 'copy-static', 'jquery-uls', 'stylesheets', 'cached-lintjs-watch'),
    parallel('webpack', 'watch')
  )
);

gulp.task('default', gulp.series('dev'));

gulp.task('hot-dev',
  series(
    'clean',
    'set-development',
    parallel('i18n', 'copy-static', 'jquery-uls', 'stylesheets-livereload', 'cached-lintjs-watch'),
    parallel('webpack', 'watch'))
);

gulp.task('build',
  series(
    'clean',
    parallel('i18n', 'copy-static', 'jquery-uls', 'stylesheets', 'lintjs'),
    parallel('webpack', 'minify'))
);
