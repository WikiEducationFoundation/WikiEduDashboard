Marked      = require 'marked'

# Set up a custom markdown renderer so links open in a new window
Renderer    = new Marked.Renderer()

Renderer.link = (href, title, text) ->
  '<a href="' + href + '" title="' + title + '" target="_blank">' + text + '</a>'

module.exports = Renderer