import { task, parallel, dest, src } from 'gulp';
import loadPlugins from 'gulp-load-plugins';
import config from '../config.js';

const plugins = loadPlugins();

task('copy-images', () => src(`${config.sourcePath}/${config.imagesDirectory}/**/*`)
    .pipe(plugins.plumber())
    .pipe(plugins.newer(`${config.outputPath}/${config.imagesDirectory}`))
    // .pipe(plugins.imagemin({
    //   optimizationLevel: 5
    // }))
    .pipe(dest(`${config.outputPath}/${config.imagesDirectory}`))
);

task('copy-fonts', () => src(`${config.sourcePath}/${config.fontsDirectory}/**/*`)
    .pipe(dest(`${config.outputPath}/${config.fontsDirectory}`))
);

task('copy-tinymce-skins', () => src('./node_modules/tinymce/skins/**/*')
    .pipe(dest(`${config.outputPath}/${config.jsDirectory}/skins`))
);

task('copy-static', parallel('copy-images', 'copy-fonts', 'copy-tinymce-skins'));
