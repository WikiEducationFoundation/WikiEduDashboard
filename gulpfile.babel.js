import { series, parallel, task } from 'gulp';
import requireDir from 'require-dir';
import stylesheets from './gulp/tasks/stylesheets';

// Require individual tasks
requireDir('./gulp/tasks', { recurse: true });

task('dev',
    series(
        'clean',
        'set-development',
        'set-watch-js',
        parallel('i18n', 'copy-static', 'jquery-uls', stylesheets, 'cached-lintjs-watch'),
        parallel('webpack', 'watch')
    )
);

task('default', series('dev'));

task('hot-dev',
    series(
        'clean',
        'set-development',
        parallel('i18n', 'copy-static', 'jquery-uls', 'stylesheets-livereload', 'cached-lintjs-watch'),
        parallel('webpack', 'watch'))
);

task('build',
    series(
        'clean',
        parallel('i18n', 'copy-static', 'jquery-uls', stylesheets, 'lintjs'),
        parallel('webpack', 'minify'))
);
