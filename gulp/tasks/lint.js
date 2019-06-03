import { task, series, src, watch } from 'gulp';
import path from 'path';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';

const plugins = loadPlugins();

const jsPath = [
  `${config.sourcePath}/${config.jsDirectory}/**/*.{jsx,js}`,
  'gulp/**/*.js',
  'gulpfile.babel.js',
  'test/**/*.{jsx,js}'
];

task('lintjs', () => src(jsPath)
  .pipe(plugins.eslint())
  .pipe(plugins.eslint.format())
  .pipe(plugins.eslint.failAfterError())
);

task('cached-lintjs', () => src(jsPath)
  .pipe(plugins.cached('eslint'))
  .pipe(plugins.eslint())
  .pipe(plugins.eslint.format())
  .pipe(plugins.eslint.result((result) => {
    if (result.warningCount > 0 || result.errorCount > 0) {
      delete plugins.cached.caches.eslint[path.resolve(result.filePath)];
    }
  }))
);

function watchCachedLintJS(done) {
  watch(jsPath, series('cached-lintjs'), (event) => {
    if (event.type === 'deleted' && plugins.cached.caches.eslint) {
      delete plugins.cached.caches.eslint[event.path];
    }
  });
  done();
}

task('cached-lintjs-watch', series('cached-lintjs', watchCachedLintJS));
