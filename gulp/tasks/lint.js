import gulp from 'gulp';
import config from '../config.js';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import path from 'path';

const jsPath = [
  `${config.sourcePath}/${config.jsDirectory}/**/*.{jsx,js}`,
  'gulp/**/*.js',
  'gulpfile.babel.js'
];

gulp.task('lintjs', () => {
  return gulp.src(jsPath)
    .pipe(plugins.eslint())
    .pipe(plugins.eslint.format())
    .pipe(plugins.eslint.failAfterError());
});

gulp.task('cached-lintjs', () => {
  return gulp.src(jsPath)
    .pipe(plugins.cached('eslint'))
    .pipe(plugins.eslint())
    .pipe(plugins.eslint.format())
    .pipe(plugins.eslint.result((result) => {
      if (result.warningCount > 0 || result.errorCount > 0) {
        delete plugins.cached.caches.eslint[path.resolve(result.filePath)];
      }
    }));
});

gulp.task('cached-lintjs-watch', ['cached-lintjs'], () => {
  return gulp.watch(jsPath, ['cached-lintjs'], (event) => {
    if (event.type === 'deleted' && plugins.cached.caches.eslint) {
      delete plugins.cached.caches.eslint[event.path];
    }
  });
});
