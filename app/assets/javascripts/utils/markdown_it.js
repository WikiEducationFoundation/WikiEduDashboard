import markdownIt from 'markdown-it';
import DOMPurify from 'dompurify';
import { assign } from 'lodash-es';
import footnotes from 'markdown-it-footnote';

// Video slides embed YouTube players as iframes, so iframes are allowed, but
// only when they point at a YouTube embed URL; any other iframe is removed.
// A separate DOMPurify instance keeps this hook from affecting other callers.
const YOUTUBE_EMBED_HOSTS = [
  'www.youtube-nocookie.com', 'youtube-nocookie.com', 'www.youtube.com', 'youtube.com'
];

const isYouTubeEmbed = (src) => {
  try {
    const url = new URL(src);
    return url.protocol === 'https:'
      && YOUTUBE_EMBED_HOSTS.includes(url.hostname)
      && url.pathname.startsWith('/embed/');
  } catch {
    return false;
  }
};

const purifier = DOMPurify(window);
purifier.addHook('afterSanitizeAttributes', (node) => {
  if (node.tagName === 'IFRAME' && !isYouTubeEmbed(node.getAttribute('src'))) {
    node.remove();
  }
});

export default function (opts) {
  const mergedOpts = assign({}, opts, { html: true, linkify: true });
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

  // `html: true` above lets raw HTML in the source pass straight through into
  // the rendered output, and callers hand that output to
  // dangerouslySetInnerHTML or `raw`. Not all of the markdown we render is
  // written by trusted people: on the Programs & Events Dashboard, training
  // modules, slides and quizzes are loaded from Meta wiki pages that are
  // intentionally left open for anyone to edit, and the training data cycle
  // re-imports them without review. Sanitizing here rather than at each call
  // site means every consumer of this helper is covered, including ones added
  // later. DOMPurify's default allow-list keeps the formatting, links, images
  // and tables that training content relies on, and drops script elements,
  // event-handler attributes and javascript: URLs.
  // `target` is not in DOMPurify's default allow-list, and dropping it would
  // silently undo the openLinksExternally rule above.
  const sanitizeOptions = {
    ADD_TAGS: ['iframe'],
    ADD_ATTR: ['target', 'allowfullscreen', 'frameborder']
  };

  ['render', 'renderInline'].forEach((method) => {
    const renderUnsafe = md[method].bind(md);
    md[method] = (...args) => purifier.sanitize(renderUnsafe(...args), sanitizeOptions);
  });

  return md;
}
