/* eslint-disable i18next/no-literal-string */
import React, { useEffect, useMemo, useState } from 'react';
import createMarkdown from '../../utils/markdown_it';

const md = createMarkdown({ openLinksExternally: true });

const DraftPreview = ({ slides, draftName, onClose }) => {
  const total = slides.length;
  const [index, setIndex] = useState(0);

  const safeIndex = Math.min(index, Math.max(0, total - 1));
  const slide = slides[safeIndex] || {};

  const renderedHtml = useMemo(
    () => md.render(slide.content || ''),
    [slide.content]
  );

  useEffect(() => {
    const handleKey = (e) => {
      if (e.key === 'ArrowLeft' && safeIndex > 0) {
        e.preventDefault();
        setIndex(safeIndex - 1);
      } else if (e.key === 'ArrowRight' && safeIndex < total - 1) {
        e.preventDefault();
        setIndex(safeIndex + 1);
      } else if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [onClose, safeIndex, total]);

  // Reset to top of preview when slide changes.
  useEffect(() => {
    const article = document.getElementById('training_module_composer__preview__article');
    if (article) article.scrollTo({ top: 0 });
  }, [safeIndex]);

  return (
    <div className="training_module_composer__preview" role="dialog" aria-label={`Preview of ${draftName || 'draft'}`}>
      <header className="training_module_composer__preview__header">
        <span className="training_module_composer__preview__count">
          Slide {safeIndex + 1} of {total}
        </span>
        <span className="training_module_composer__preview__hint">
          ← / → to navigate · Esc to close
        </span>
        <button
          type="button"
          className="training_module_composer__preview__close"
          onClick={onClose}
          aria-label="Close preview"
        >
          ×
        </button>
      </header>
      <article
        id="training_module_composer__preview__article"
        className="training__slide training_module_composer__preview__article"
      >
        <h1 className="training_module_composer__preview__title">
          {slide.title || <em>Untitled slide</em>}
        </h1>
        <div
          className="markdown training__slide__content"
          dangerouslySetInnerHTML={{ __html: renderedHtml }}
        />
        <footer className="training__slide__footer training_module_composer__preview__footer">
          <button
            type="button"
            className="button"
            onClick={() => setIndex(safeIndex - 1)}
            disabled={safeIndex === 0}
          >
            ← Previous
          </button>
          <span className="training_module_composer__preview__slug">
            {slide.slug || `slide-${safeIndex + 1}`}
          </span>
          <button
            type="button"
            className="button dark"
            onClick={() => setIndex(safeIndex + 1)}
            disabled={safeIndex >= total - 1}
          >
            Next →
          </button>
        </footer>
      </article>
    </div>
  );
};

export default DraftPreview;
