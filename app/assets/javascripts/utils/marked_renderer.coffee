Marked      = require 'marked'

# Set up a custom markdown renderer so links open in a new window
Renderer    = new Marked.Renderer()

Renderer.link = (href, title, text) ->
  conditional_title = if title? then "title='#{title}" else ''
  "<a href='#{href}' #{conditional_title} target='_blank'>#{text}</a>"

module.exports = Renderer