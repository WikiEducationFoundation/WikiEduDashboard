import { task } from 'gulp';
import config from '../config.js';

task('set-development', (done) => {
  config.development = true;
  done();
});

task('set-watch-js', (done) => {
  config.watch_js = true;
  done();
});
