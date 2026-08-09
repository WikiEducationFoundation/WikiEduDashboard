import { Node, mergeAttributes } from '@tiptap/core';

// Allows YouTube <iframe> embeds to survive the editor round-trip. TipTap's
// schema drops any element it has no node for, which is why embeds were being
// stripped from Timeline blocks. Restricted to YouTube hosts to avoid allowing
// arbitrary iframes in user-generated content.
const YOUTUBE_HOST = /^https:\/\/(www\.)?(youtube\.com|youtube-nocookie\.com)\/embed\//;

export default Node.create({
  name: 'youtubeIframe',
  group: 'block',
  atom: true,
  selectable: true,

  addAttributes() {
    return {
      src: { default: null },
      width: { default: '560' },
      height: { default: '315' },
      frameborder: { default: '0' },
      allowfullscreen: { default: 'true' },
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
