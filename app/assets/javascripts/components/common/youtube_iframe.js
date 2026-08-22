import { Node, mergeAttributes } from '@tiptap/core';

// Allows YouTube <iframe> embeds to survive the editor round-trip. TipTap's
// schema drops any element it has no node for, which is why embeds were being
// stripped from Timeline blocks. Matches are restricted to YouTube embed
// hosts to keep embed content consistent. Note this is a content-fidelity
// rule, not a security boundary: source mode passes raw HTML through unparsed.
const YOUTUBE_HOST = /^https:\/\/(www\.)?(youtube\.com|youtube-nocookie\.com)\/embed\//;

export default Node.create({
  name: 'youtubeIframe',
  group: 'block',
  atom: true,
  selectable: true,

  addAttributes() {
    return {
      src: { default: null },
      width: { default: null },
      height: { default: null },
      frameborder: { default: null },
      allowfullscreen: { default: null },
      allow: { default: null },
      title: { default: null },
      class: { default: null },
      referrerpolicy: { default: null },
    };
  },

  parseHTML() {
    return [{
      tag: 'iframe',
      getAttrs: (el) => {
        const src = el.getAttribute('src') || '';
        return YOUTUBE_HOST.test(src) ? {} : false;
      },
    }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['iframe', mergeAttributes(HTMLAttributes)];
  },
});
