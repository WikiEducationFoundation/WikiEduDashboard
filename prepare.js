/* eslint no-console: ["error", { allow: ["log"] }] */

function elapsed(hrtime) {
  const seconds = (hrtime[0] + (hrtime[1] / 1e9)).toFixed(3);
  start = process.hrtime(); // reset the time
  return seconds;
}

let start = process.hrtime();
const execSync = require('child_process').execSync;
const config = require('./config');

// cleans the stale assets
console.log('Started cleaning stale assets');
execSync(`rm -rf ${config.outputPath}`);
console.log('\x1b[33m%s\x1b[0m', `Finished cleaning stale assets after ${elapsed(process.hrtime(start))} seconds`);

// export i18n files
console.log('Started emitting i18n translations');
execSync('bundle exec i18n export -c ./config/i18n-js.yml');
console.log('\x1b[33m%s\x1b[0m', `Finished emitting i18n translations after ${elapsed(process.hrtime(start))} seconds`);

// copies static assets from the source to assets folder
const copyPaths = [{
  from: './node_modules/jquery/dist/jquery.min.js',
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
}, {
  from: './node_modules/tinymce/models',
  to: `${config.outputPath}/${config.jsDirectory}/models`,
}];
copyPaths.forEach((entry, idx) => {
  switch (idx) {
    case 0: console.log('Started copying jQuery'); break;
    case 1: console.log('Started copying images'); break;
    case 2: console.log('Started copying fonts'); break;
    case 3: console.log('Started copying tinymce skins'); break;
    case 4: console.log('Started copying tinymce model'); break;
    default: console.log('Started copying static assets'); break;
  }
  execSync(`cp -r ${entry.from} ${entry.to}`);
  switch (idx) {
    case 0: console.log('\x1b[33m%s\x1b[0m', `Finished copying jQuery after ${elapsed(process.hrtime(start))} seconds`); break;
    case 1: console.log('\x1b[33m%s\x1b[0m', `Finished copying images after ${elapsed(process.hrtime(start))} seconds`); break;
    case 2: console.log('\x1b[33m%s\x1b[0m', `Finished copying fonts after ${elapsed(process.hrtime(start))} seconds`); break;
    case 3: console.log('\x1b[33m%s\x1b[0m', `Finished copying tinymce skins after ${elapsed(process.hrtime(start))} seconds`); break;
    case 4: console.log('\x1b[33m%s\x1b[0m', `Finished copying tinymce model after ${elapsed(process.hrtime(start))} seconds`); break;
    default: console.log('\x1b[33m%s\x1b[0m', `Finished copying static assets after ${elapsed(process.hrtime(start))} seconds`); break;
  }
});
