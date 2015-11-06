MarkdownIt = require('markdown-it')

module.exports = (opts) ->
  mergedOpts = _.assign({}, opts, { html: true, linkify: true })
  md = MarkdownIt(mergedOpts)

  if mergedOpts.openLinksExternally
    defaultRender = md.renderer.rules.link_open || (tokens, idx, options, env, self) ->
      self.renderToken(tokens, idx, options)

    md.renderer.rules.link_open = (tokens, idx, options, env, self) ->
      aIndex = tokens[idx].attrIndex('target')

      if (aIndex < 0)
        tokens[idx].attrPush(['target', '_blank']); # add new attribute
      else
        tokens[idx].attrs[aIndex][1] = '_blank';    # replace value of existing attr

      # pass token to default renderer.
      return defaultRender(tokens, idx, options, env, self);

  return md

