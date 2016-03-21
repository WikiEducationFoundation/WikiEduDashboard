#--------------------------------------------------------
# Config Variables
#--------------------------------------------------------

Config = ->

  # Development mode
  @development = false

  # Source path
  @sourcePath = "app/assets"

  # View path
  @viewPath = "app/views"

  # Compile path
  @outputPath = "public/assets"

  # Public directory
  @publicPath = "public"

  # Test path
  @testPath = "test"

  # Directory where vendor files live
  @vendorPath = "vendor"

  # Name of JavaScript directory
  @jsDirectory = "javascripts"

  # Name of CSS directory
  @cssDirectory = "stylesheets"

  # Name of Images directory
  @imagesDirectory = "images"

  # Name of SVG directory
  @svgDirectory = "svg"

  # Name of Fonts directory
  @fontsDirectory = "fonts"

  # Name of main JS file
  @jsMainFile = "main"

  # Name of main CSS file
  @cssMainFiles = "+(main|training|surveys)"


module.exports = new Config()
