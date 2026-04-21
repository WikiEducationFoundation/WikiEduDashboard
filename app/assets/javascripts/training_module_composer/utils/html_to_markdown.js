import TurndownService from 'turndown';

// Google Docs wraps the entire pasted selection in a <b id="docs-internal-guid-...">
// with CSS `font-weight: normal`. If we don't strip it, the whole paste is
// treated as one giant bold block. We also drop class, id, and inline-style
// attributes that confuse turndown's rule matching.
const cleanGoogleDocsHtml = (html) => {
  if (!html) return '';
  let cleaned = html;

  // Strip any <b id="docs-internal-guid-*"> wrappers (the regex is global so
  // nested occurrences are all stripped).
  cleaned = cleaned.replace(/<b\b[^>]*id="docs-internal-guid-[^"]*"[^>]*>/gi, '');

  // Replace any <b>/<span>/<font> with font-weight:normal inline style — those
  // exist only to counteract an outer bold wrapper and should be treated as
  // plain text.
  cleaned = cleaned.replace(
    /<(b|span|font)\b[^>]*font-weight:\s*normal[^>]*>/gi,
    '<span>'
  );

  // Remove id, class, and style attributes wholesale. The paste path only
  // cares about structure (headings, lists, links, emphasis), not formatting.
  cleaned = cleaned.replace(/\s(?:id|class|style)="[^"]*"/gi, '');

  return cleaned;
};

const service = new TurndownService({
  headingStyle: 'atx',
  bulletListMarker: '-',
  codeBlockStyle: 'fenced',
  emDelimiter: '_'
});

// Drop elements that don't translate meaningfully into a slide draft.
service.remove(['script', 'style', 'head', 'meta', 'link']);

export const htmlToMarkdown = (html) => {
  const cleaned = cleanGoogleDocsHtml(html);
  return service.turndown(cleaned).trim();
};

export default htmlToMarkdown;
