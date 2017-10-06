import gulp from 'gulp';
import loadPlugins from 'gulp-load-plugins';
const plugins = loadPlugins();
import config from '../config.js';

gulp.task('icon-font', () => {
  const cssTemplateFilename = 'icon-font-template.css';
  const cssOutputFilename = '_icons.styl';
  const fontName = 'icons';
  const fontPath = '../fonts/';
  const className = 'icon';

  // Grab SVGs from 'svg' directory
  const fileSvgStream = gulp.src(`${config.sourcePath}/${config.svgDirectory}/*.svg`);

  // Generate Font and CSS from all SVGs
  return fileSvgStream
    .pipe(plugins.iconfont({
      fontName,
      normalize: true
    }).on('glyphs', (glyphs) => {
      const mapped = glyphs.map((glyph) => {
        return {
          name: glyph.name,
          codepoint: glyph.unicode[0].charCodeAt(0)
        };
      });

      return gulp.src(`${config.sourcePath}/${config.svgDirectory}/${cssTemplateFilename}`)
        .pipe(plugins.consolidate('lodash', {
          glyphs: mapped,
          fontName,
          fontPath,
          className
        }))
        .pipe(plugins.rename(cssOutputFilename))
        .pipe(gulp.dest(`${config.sourcePath}/${config.cssDirectory}`));
    })).pipe(gulp.dest(`${config.sourcePath}/${config.fontsDirectory}`));
});
