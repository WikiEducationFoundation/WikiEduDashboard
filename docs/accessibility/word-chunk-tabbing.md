# Word-chunk tabbing (per-chunk keyboard navigation) 

## Summary 
This document describes the implementation of "word chunk" tabbing used in the Article Viewer to provide word chunk navigation for screen reader users. The feature converts paragraph text into short, focusable "chunks" so users can Tab through text and use Arrow Up/Down to move between paragraphs.

## Why this exists 
- Improve readability for screen-reader users by presenting short natural reading units (chunks) instead of single words or entire paragraphs.  
- Allow quick keyboard navigation between paragraphs (Arrow Up/Down) while preserving link behavior and other inline elements.
- Address the lack of navigation method in Article Viewer

## Where to find the implementation 
- File: `app/assets/javascripts/components/common/ArticleViewer/components/ParsedArticle.jsx`

Key functions and logic:
- createWordSpans(p): converts a paragraph into a sequence of `.article-chunk` <span>s. Each chunk:
  - uses `class="article-chunk"`
  - is focusable (`tabindex="0"`) and uses `role="text"`
  - contains a short run of text ending at punctuation, a link, or paragraph end
- Punctuation (.,;:!?—) triggers a chunk boundary
- Links (`<a>`) are treated as chunk boundaries and are cloned into the chunk stream to preserve behavior

Accessibility tweaks:
- Editor highlight spans (`.editor-token`) are marked with `aria-hidden="true"`, `role="presentation"` and `tabindex="-1"` to avoid being read word-by-word.
- When a chunk gets focus, the handler temporarily sets `aria-hidden="true"` on nearby elements that have `[aria-label]`, `.editor-token`, or `[role="group"]` so VoiceOver does not announce group labels/usernames while reading chunks.

Keyboard navigation:
- ArrowDown: focuses the first chunk of the next paragraph
- ArrowUp: focuses the last chunk of the previous paragraph
- Chunks are focused via `.focus()` in keyboard handlers attached to the article container

## Implementation notes / important snippets 
- Chunk creation ensures assistive tech treats each chunk as plain text:

span.className = 'article-chunk';
span.setAttribute('tabindex', '0');
span.setAttribute('role', 'text');
span.textContent = current;