import React, { useRef, useState } from 'react';
import { parsePaste } from '../api.js';
import { htmlToMarkdown } from '../utils/html_to_markdown.js';

const PasteImportModal = ({ onApply, onClose, hasExistingSlides }) => {
  const textareaRef = useRef(null);
  const [markdown, setMarkdown] = useState('');
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [convertedFromHtml, setConvertedFromHtml] = useState(false);

  const insertAtSelection = (insertion) => {
    const el = textareaRef.current;
    if (!el) {
      setMarkdown(prev => prev + insertion);
      return;
    }
    const start = el.selectionStart;
    const end = el.selectionEnd;
    const before = el.value.substring(0, start);
    const after = el.value.substring(end);
    const next = before + insertion + after;
    setMarkdown(next);
    // Restore cursor position to the end of the inserted text.
    requestAnimationFrame(() => {
      const caret = start + insertion.length;
      el.selectionStart = caret;
      el.selectionEnd = caret;
    });
  };

  const handlePaste = (event) => {
    const html = event.clipboardData && event.clipboardData.getData('text/html');
    if (!html) return; // fall through to default plain-text paste
    event.preventDefault();
    try {
      const converted = htmlToMarkdown(html);
      insertAtSelection(converted);
      setConvertedFromHtml(true);
    } catch (e) {
      // If conversion fails for any reason, fall back to plain-text content.
      const plain = event.clipboardData.getData('text/plain');
      insertAtSelection(plain);
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError(null);
    setBusy(true);
    try {
      const { slides } = await parsePaste(markdown);
      if (hasExistingSlides) {
        const ok = window.confirm(
          `This will replace all ${hasExistingSlides} existing slides with ${slides.length} new ones. Continue?`
        );
        if (!ok) { setBusy(false); return; }
      }
      onApply(slides);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="training_module_composer__modal__backdrop" role="presentation" onClick={onClose}>
      <div
        className="training_module_composer__modal"
        role="dialog"
        aria-labelledby="paste_import_title"
        onClick={e => e.stopPropagation()}
      >
        <h2 id="paste_import_title">Paste module content</h2>
        <p>
          Paste directly from a Google Doc — headings styled as <strong>Heading 1</strong> or{' '}
          <strong>Heading 2</strong> become slide titles. Whichever level appears first in the
          paste becomes the slide separator. Plain markdown works too (use <code>#</code> or{' '}
          <code>##</code>). Existing slides will be replaced.
        </p>
        <form onSubmit={handleSubmit}>
          <textarea
            ref={textareaRef}
            rows={16}
            value={markdown}
            onChange={e => setMarkdown(e.target.value)}
            onPaste={handlePaste}
            placeholder={'# First slide\nContent for the first slide.\n\n# Second slide\nContent for the second slide.'}
            required
          />
          {convertedFromHtml && (
            <small className="training_module_composer__modal__hint">
              Converted from rich text. Review the markdown above before applying.
            </small>
          )}
          {error && <div className="notification error">{error}</div>}
          <div className="training_module_composer__modal__actions">
            <button type="button" className="button" onClick={onClose} disabled={busy}>
              Cancel
            </button>
            <button type="submit" className="button dark" disabled={busy || !markdown.trim()}>
              {busy ? 'Parsing…' : 'Replace slides'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PasteImportModal;
