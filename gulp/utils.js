import fs from 'fs';
import mkdirp from 'mkdirp';

module.exports = {
  update_manifest(dir, mainFile) {
    let manifest = {};
    try {
      manifest = JSON.parse(fs.readFileSync(`${dir}/rev-manifest.json`, 'utf8'));
    } catch (e) {
       // ignore
    }

    if (!(manifest[mainFile] === mainFile)) {
      const oldFile = manifest[mainFile];
      if (oldFile) {
        try {
          fs.unlinkSync(`${dir}/${oldFile}`);
        } catch (e) {
          // ignore
        }
      }

      manifest[mainFile] = mainFile;
      mkdirp.sync(`${dir}/`);
      fs.writeFileSync(`${dir}/rev-manifest.json`, JSON.stringify(manifest));
    }
  }
};
