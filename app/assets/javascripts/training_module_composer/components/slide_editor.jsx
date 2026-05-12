/* eslint-disable i18next/no-literal-string */
import React, { useMemo, useRef, useState } from 'react';
import createMarkdown from '../../utils/markdown_it';
import { slugifyTitle } from '../utils/slugify.js';
import { MarkdownCheatsheetToggle, MarkdownCheatsheetPanel } from './markdown_cheatsheet.jsx';
import CommonsImagePicker from './commons_image_picker.jsx';

const md = createMarkdown({ openLinksExternally: true });

const collisionMessage = (collision, slug) => {
  if (collision === 'existing') {
    return `Slug "${slug}" is already used by a training slide in the codebase. Change it or the module will fail to load.`;
  }
  if (collision === 'duplicate') {
    return `Slug "${slug}" is used by another slide in this draft.`;
  }
  return null;
};

const SlideEditor = ({ slide, index, moduleId, onChange, collision }) => {
  const derivedSlug = useMemo(() => slugifyTitle(slide.title), [slide.title]);
  const effectiveSlug = slide.slug || derivedSlug;
  const previewHtml = useMemo(() => md.render(slide.content || ''), [slide.content]);
  const slideId = moduleId ? moduleId * 100 + index + 1 : null;
  const filename = `${slideId ? String(slideId).padStart(4, '0') : '—'}-${effectiveSlug || 'slug'}.yml`;
  const [cheatsheetOpen, setCheatsheetOpen] = useState(false);
  const toggleCheatsheet = () => setCheatsheetOpen(open => !open);
  const [imagePickerOpen, setImagePickerOpen] = useState(false);
  const textareaRef = useRef(null);

  const handleInsertImage = (markup) => {
    const ta = textareaRef.current;
    const current = slide.content || '';
    const start = ta ? ta.selectionStart : current.length;
    const end = ta ? ta.selectionEnd : current.length;
    const before = current.slice(0, start);
    const after = current.slice(end);
    const next = `${before}${markup}${after}`;
    onChange({ content: next });
    setImagePickerOpen(false);
    requestAnimationFrame(() => {
      if (!ta) return;
      ta.focus();
      const caret = start + markup.length;
      ta.selectionStart = caret;
      ta.selectionEnd = caret;
    });
  };

  const handleTitleChange = (event) => {
    const newTitle = event.target.value;
    // If the slug hasn't been customized (matches old derivedSlug), follow the title.
    const nextSlug = (!slide.slug || slide.slug === slugifyTitle(slide.title))
      ? slugifyTitle(newTitle)
      : slide.slug;
    onChange({ title: newTitle, slug: nextSlug });
  };

  return (
    <div className="training_module_composer__editor">
      <div className="training_module_composer__editor__meta">
        <div className="training_module_composer__field">
          <label htmlFor="slide_title">Slide title</label>
          <input
            id="slide_title"
            type="text"
            value={slide.title}
            onChange={handleTitleChange}
          />
        </div>

        <div className={`training_module_composer__field${collision ? ' has-collision' : ''}`}>
          <label htmlFor="slide_slug">Slide slug</label>
          <input
            id="slide_slug"
            type="text"
            value={slide.slug || ''}
            placeholder={derivedSlug}
            onChange={e => onChange({ slug: e.target.value })}
          />
          {collision ? (
            <small className="training_module_composer__collision">
              {collisionMessage(collision, effectiveSlug)}
            </small>
          ) : (
            <small><code>{filename}</code></small>
          )}
        </div>
      </div>

      <div className="training_module_composer__editor__panes">
        <div className="training_module_composer__field training_module_composer__editor__source">
          <div className="training_module_composer__editor__source__label">
            <label htmlFor="slide_content">Markdown</label>
            <MarkdownCheatsheetToggle isOpen={cheatsheetOpen} onToggle={toggleCheatsheet} />
            <button
              type="button"
              className="training_module_composer__cheatsheet__toggle"
              onClick={() => setImagePickerOpen(true)}
            >
              insert image
            </button>
          </div>
          {cheatsheetOpen && <MarkdownCheatsheetPanel onClose={toggleCheatsheet} />}
          <textarea
            ref={textareaRef}
            id="slide_content"
            rows={14}
            value={slide.content}
            onChange={e => onChange({ content: e.target.value })}
          />
        </div>
        {imagePickerOpen && (
          <CommonsImagePicker
            onInsert={handleInsertImage}
            onClose={() => setImagePickerOpen(false)}
          />
        )}

        <div className="training_module_composer__editor__preview">
          <label>Preview</label>
          <div className="training__slide training__slide__content">
            <h2>{slide.title || <em>Untitled slide</em>}</h2>
            <div dangerouslySetInnerHTML={{ __html: previewHtml }} />
          </div>
        </div>
      </div>
    </div>
  );
};

export default SlideEditor;
