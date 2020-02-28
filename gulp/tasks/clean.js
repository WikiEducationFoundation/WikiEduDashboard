import { task } from 'gulp';
import del from 'del';
import config from '../config.js';

task('clean', () => del([
  `${config.outputPath}/fonts/*`,
  `${config.outputPath}/images/*`,
  `${config.outputPath}/stylesheets/*`,
  `${config.outputPath}/javascripts/**`,
  `!${config.outputPath}/javascripts/jquery-uls.js`,
  `!${config.outputPath}/javascripts/i18n/**`,
  `!${config.outputPath}/javascripts/i18n.js`
]));
