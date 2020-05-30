const execSync = require('child_process').execSync;
const config = require('./config');

execSync(`rm -rf ${config.outputPath} && bundle exec rails i18n:js:export`);
const jqueryUlsPath = './node_modules/jquery/dist/jquery.min.js';

const copyPaths = [{
  from: jqueryUlsPath,
  to: `${config.outputPath}/${config.jsDirectory}`,
}, {
  from: `${config.sourcePath}/${config.imagesDirectory}`,
  to: `${config.outputPath}/${config.imagesDirectory}`,
}, {
  from: `${config.sourcePath}/${config.fontsDirectory}`,
  to: `${config.outputPath}/${config.fontsDirectory}`,
}, {
  from: './node_modules/tinymce/skins',
  to: `${config.outputPath}/${config.jsDirectory}/skins`,
}];

copyPaths.forEach(entry =>
  execSync(`cp -r ${entry.from} ${entry.to}`));

