//--------------------------------------------------------
// Config Variables
//--------------------------------------------------------

const Config = function () {
  // Development mode
  this.development = false;

  // Source path
  this.sourcePath = 'app/assets';

  // View path
  this.viewPath = 'app/views';

  // Compile path
  this.outputPath = 'public/assets';

  // Public directory
  this.publicPath = 'public';

  // Test path
  this.testPath = 'test';

  // Directory where vendor files live
  this.vendorPath = 'vendor';

  // Name of JavaScript directory
  this.jsDirectory = 'javascripts';

  // Name of CSS directory
  this.cssDirectory = 'stylesheets';

  // Name of Images directory
  this.imagesDirectory = 'images';

  // Name of SVG directory
  this.svgDirectory = 'svg';

  // Name of Fonts directory
  this.fontsDirectory = 'fonts';

  // Name of main JS file
  this.jsMainFile = 'main';

  // Name of main CSS file
  this.cssMainFiles = '+(main|training|surveys)';
};


export default new Config();
