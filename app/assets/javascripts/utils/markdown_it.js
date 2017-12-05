import markdownIt from 'markdown-it';
import _ from 'lodash';
import footnotes from 'markdown-it-footnote';

export default function (opts) {
  const mergedOpts = _.assign({}, opts, { html: true, linkify: true });
  const md = markdownIt(mergedOpts).use(footnotes);

  if (mergedOpts.openLinksExternally) {
    // Remember old renderer, if overriden, or proxy to default renderer
    const defaultRender = md.renderer.rules.link_open || function (tokens, idx, options, env, self) {
      return self.renderToken(tokens, idx, options);
    };

    md.renderer.rules.link_open = function (tokens, idx, options, env, self) {
      const aIndex = tokens[idx].attrIndex('target');

      if (aIndex < 0) {
        tokens[idx].attrPush(['target', '_blank']); // add new attribute
      } else {
        tokens[idx].attrs[aIndex][1] = '_blank'; // replace value of existing attr
      }

      // pass token to default renderer.
      return defaultRender(tokens, idx, options, env, self);
    };
  }

  return md;
}
