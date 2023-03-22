/* eslint no-console: ["error", { allow: ["log"] }] */

function elapsed(hrtime) {
  const seconds = (hrtime[0] + (hrtime[1] / 1e9)).toFixed(3);
  start = process.hrtime(); // reset the time
  return seconds;
}

function getHashOfI18nFiles() {
  // we use the sha1sum of the i18n files to determine if we need to rebuild
  return execSync('cat config/locales/* | sha1sum').toString().split('-')[0].trim();
}

let start = process.hrtime();
const execSync = require('child_process').execSync;
const exec = require('child_process').exec;

const config = require('./config');
const fs = require('fs');

const path = require('path');

const isWindows = process.platform === 'win32';

let fullRebuild = false;

try {
  const lastHash = fs.readFileSync(`${config.buildCache}/i18n/hash.txt`).toString();
  const currentHash = getHashOfI18nFiles();

  // check if the previous hash is the same as the current hash
  // if same, we can skip the i18n export
  fullRebuild = lastHash.trim() !== currentHash.trim();
} catch (e)  {
  // if however, the cache files are not found, we need to rebuild
  const i18nCachePath = isWindows ? '.\\build_cache\\i18n' : `${config.buildCache}/i18n`;

  if (!fs.existsSync(i18nCachePath)) {
    const cmd = isWindows ? `mkdir ${i18nCachePath}` : `mkdir -p ${i18nCachePath}`;
    execSync(cmd);
  } else {
    console.log(`${i18nCachePath} already exists`);
  }

  fullRebuild = true;
  }

// cleans the stale assets
console.log('Started cleaning stale assets');
const outputPath = path.normalize(config.outputPath);

// Check if the directory exists before attempting to delete it
if (fs.existsSync(outputPath)) {
  // Use path.join to construct the path using the correct path separator
  const cmd = isWindows ? `rmdir /s /q "${outputPath}"` : `rm -rf "${outputPath}"`;
  execSync(cmd);
  console.log('\x1b[33m%s\x1b[0m', `Finished cleaning stale assets after ${elapsed(process.hrtime(start))} seconds`);
}

if (fullRebuild) {
  // export i18n files
  console.log('Started emitting i18n translations');
  execSync('bundle exec i18n export -c ./config/i18n-js.yml');
  console.log('\x1b[33m%s\x1b[0m', `Finished emitting i18n translations after ${elapsed(process.hrtime(start))} seconds`);

  const hash = getHashOfI18nFiles();

  // copy i18n files to cache
  exec(`cp ${config.outputPath}/${config.jsDirectory}/i18n.js ${config.buildCache}/i18n/i18n.js`);
  exec(`cp ${config.outputPath}/${config.jsDirectory}/i18n ${config.buildCache}/i18n/i18n -r`);

  // write the hash value
  fs.writeFile(`${config.buildCache}/i18n/hash.txt`, hash, () => {
    console.log('Updated cache');
  });
} else {
  console.log('\x1b[33m%s\x1b[0m', 'Skipping i18n export - found cached version');
  const i18nDir = isWindows ? '.\\config.outputPath\\config.jsDirectory' : `${config.outputPath}/${config.jsDirectory}`;
  if (!fs.existsSync(i18nDir)) {
  const cmt = isWindows ? 'mkdir .\\config.outputPath\\config.jsDirectory' : `mkdir -p ${config.outputPath}/${config.jsDirectory}`;
  execSync(cmt);
} else {
  console.log('i18n directory already exists, skipping mkdir');
}
}

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
}];

// if we're not doing a full rebuild, we need to copy the files from the cache to the output folder
if (!fullRebuild) {
  copyPaths.push({
    from: `${config.buildCache}/i18n/i18n.js`,
    to: `${config.outputPath}/${config.jsDirectory}`,
  });
  copyPaths.push({
    from: `${config.buildCache}/i18n/i18n`,
    to: `${config.outputPath}/${config.jsDirectory}`,
  });
}

copyPaths.forEach((entry, idx) => {
  switch (idx) {
    case 0: console.log('Started copying jQuery'); break;
    case 1: console.log('Started copying images'); break;
    case 2: console.log('Started copying fonts'); break;
    case 3: console.log('Started copying tinymce skins'); break;
    case 4:
      console.log('Started copying i18n javascript');
      break;
    case 5:
      console.log('Started copying i18n locales');
      break;
    default: console.log('Started copying static assets'); break;
  }

  exec(`cp -r ${entry.from} ${entry.to}`, () => {
    switch (idx) {
      case 0: console.log('\x1b[33m%s\x1b[0m', `Finished copying jQuery after ${elapsed(process.hrtime(start))} seconds`); break;
      case 1: console.log('\x1b[33m%s\x1b[0m', `Finished copying images after ${elapsed(process.hrtime(start))} seconds`); break;
      case 2: console.log('\x1b[33m%s\x1b[0m', `Finished copying fonts after ${elapsed(process.hrtime(start))} seconds`); break;
      case 3: console.log('\x1b[33m%s\x1b[0m', `Finished copying tinymce skins after ${elapsed(process.hrtime(start))} seconds`); break;
      case 4: console.log('\x1b[33m%s\x1b[0m', `Finished copying i18n javascript after ${elapsed(process.hrtime(start))} seconds`); break;
      case 5: console.log('\x1b[33m%s\x1b[0m', `Finished copying i18n locales after ${elapsed(process.hrtime(start))} seconds`); break;
      default: console.log('\x1b[33m%s\x1b[0m', `Finished copying static assets after ${elapsed(process.hrtime(start))} seconds`); break;
    }
  });
});