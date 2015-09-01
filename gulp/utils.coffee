fs      = require 'fs'
path    = require 'path'
mkdirp  = require 'mkdirp'

module.exports =
  update_manifest: (dir, main_file) ->
    manifest = {}
    try
      manifest = JSON.parse(fs.readFileSync("#{dir}/rev-manifest.json", "utf8"))
    catch e

    unless manifest[main_file] == main_file
      old_file = manifest[main_file]
      if old_file
        try
          fs.unlinkSync("#{dir}/#{old_file}")
        catch e

      manifest[main_file] = main_file
      console.log("mkdirp", "#{dir}/")
      mkdirp.sync "#{dir}/"
      fs.writeFileSync("#{dir}/rev-manifest.json", JSON.stringify(manifest))
