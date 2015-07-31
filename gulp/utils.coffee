module.exports =
  update_manifest: (dir, main_file) ->
    fs = require('fs')
    manifest_file = fs.readFileSync("#{dir}/rev-manifest.json", "utf8")
    old_manifest = JSON.parse(manifest_file)
    unless old_manifest[main_file] == main_file
      manifest = {}
      old_file = old_manifest[main_file]
      fs.unlinkSync("#{dir}/#{old_file}")
      manifest[main_file] = main_file
      fs.writeFileSync("#{dir}/rev-manifest.json", JSON.stringify(manifest))
