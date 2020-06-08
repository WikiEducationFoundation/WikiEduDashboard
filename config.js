//--------------------------------------------------------
// Config Variables
//--------------------------------------------------------

module.exports = {
  // Source path
  sourcePath: 'app/assets',

  // View path
  viewPath: 'app/views',

  // Compile path
  outputPath: 'public/assets',

  // Public directory
  publicPath: 'public',

  // Test path
  testPath: 'test',

  // Directory where vendor files live
  vendorPath: 'vendor',

  // Name of JavaScript directory
  jsDirectory: 'javascripts',

  // Name of CSS directory
  cssDirectory: 'stylesheets',

  // Name of Images directory
  imagesDirectory: 'images',

  // Name of SVG directory
  svgDirectory: 'svg',

  // Name of Fonts directory
  fontsDirectory: 'fonts',

  // Name of main JS file
  jsMainFile: 'main',

  // Name of main CSS file
  cssMainFiles: '+(main|training|surveys|styleguide)',

  // The below feature sets are required for the lodash functions we use.
  // If in future, there is a need to use an additional lodash method other than what we already use,
  // make sure that the function belongs to one of the feature sets enabled below and if not,
  // enable the appropriate feature set by adding to the below config for the function to work as expected.
  // https://github.com/lodash/lodash-webpack-plugin#feature-sets
  requiredLodashFeatures: {
    collections: true,
    shorthands: true,
    flattening: true
  }
};
