import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';

// A lightweight TipTap-based rich text editor. It replaces the previous TinyMCE
// editor used by TextAreaInput's `wysiwyg` mode. The external contract is the
// same: it is given an HTML string `value` and reports edits back through
// `onChange({ target: { value: html } }, html)`, so InputHOC keeps working
// unchanged. A source-view toggle exposes the raw HTML for the cases (e.g. some
// Timeline blocks) where editing the markup directly is needed.

// Returns '' for an empty document so callers that treat an empty editor as a
// falsy value (e.g. disabling a submit button) keep behaving as before, rather
// than seeing TipTap's empty "<p></p>".
const htmlOf = editor => (editor.isEmpty ? '' : editor.getHTML());

const ToolbarButton = ({ onClick, isActive, label, disabled }) => (
  <button
    type="button"
    className={`wysiwyg-editor__btn${isActive ? ' is-active' : ''}`}
    // Keep the editor selection while clicking a toolbar button.
    onMouseDown={e => e.preventDefault()}
    onClick={onClick}
    title={label}
    aria-label={label}
    aria-pressed={!!isActive}
    disabled={disabled}
  >
    {label}
  </button>
);

ToolbarButton.propTypes = {
  onClick: PropTypes.func.isRequired,
  isActive: PropTypes.bool,
  label: PropTypes.string.isRequired,
  disabled: PropTypes.bool,
};

const WysiwygEditor = ({ value, onChange, onFocus, onBlur, invalid }) => {
  const [sourceMode, setSourceMode] = useState(false);
  const [sourceHtml, setSourceHtml] = useState(value || '');

  const editor = useEditor({
    extensions: [
      StarterKit.configure({ link: { openOnClick: false } }),
    ],
    content: value || '',
    immediatelyRender: true,
    editorProps: {
      attributes: { class: `wysiwyg-editor__content${invalid ? ' invalid' : ''}` },
    },
    onUpdate: ({ editor: ed }) => {
      const html = htmlOf(ed);
      onChange({ target: { value: html } }, html);
    },
    onFocus: () => onFocus && onFocus(),
    onBlur: () => onBlur && onBlur(),
  });

  // Sync programmatic value changes (e.g. a reset) into the editor without
  // disturbing the cursor during normal typing.
  useEffect(() => {
    if (!editor || sourceMode) return;
    if ((value || '') !== htmlOf(editor)) {
      editor.commands.setContent(value || '', false);
    }
  }, [value, editor, sourceMode]);

  if (!editor) return null;

  const headingValue = () => {
    for (let level = 2; level <= 4; level += 1) {
      if (editor.isActive('heading', { level })) return String(level);
    }
    return 'paragraph';
  };

  const onFormatChange = (e) => {
    const selected = e.target.value;
    if (selected === 'paragraph') {
      editor.chain().focus().setParagraph().run();
    } else {
      editor.chain().focus().setHeading({ level: Number(selected) }).run();
    }
  };

  const onLink = () => {
    const previous = editor.getAttributes('link').href;
    const url = window.prompt('Link URL', previous || 'https://');
    if (url === null) return;
    if (url === '') {
      editor.chain().focus().extendMarkRange('link').unsetLink().run();
      return;
    }
    editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
  };

  const enterSourceMode = () => {
    setSourceHtml(htmlOf(editor));
    setSourceMode(true);
  };

  const exitSourceMode = () => {
    editor.commands.setContent(sourceHtml || '', true);
    const html = htmlOf(editor);
    onChange({ target: { value: html } }, html);
    setSourceMode(false);
  };

  const onSourceChange = (e) => {
    const html = e.target.value;
    setSourceHtml(html);
    onChange({ target: { value: html } }, html);
  };

  return (
    <div className="wysiwyg-editor">
      <div className="wysiwyg-editor__toolbar" role="toolbar" aria-label="Formatting">
        <select
          className="wysiwyg-editor__select"
          aria-label="Text style"
          value={headingValue()}
          onChange={onFormatChange}
          disabled={sourceMode}
        >
          <option value="paragraph">Paragraph</option>
          <option value="2">Heading 2</option>
          <option value="3">Heading 3</option>
          <option value="4">Heading 4</option>
        </select>
        <ToolbarButton onClick={() => editor.chain().focus().toggleBold().run()} isActive={editor.isActive('bold')} label="Bold" disabled={sourceMode} />
        <ToolbarButton onClick={() => editor.chain().focus().toggleItalic().run()} isActive={editor.isActive('italic')} label="Italic" disabled={sourceMode} />
        <ToolbarButton onClick={() => editor.chain().focus().toggleBulletList().run()} isActive={editor.isActive('bulletList')} label="Bullet list" disabled={sourceMode} />
        <ToolbarButton onClick={() => editor.chain().focus().toggleOrderedList().run()} isActive={editor.isActive('orderedList')} label="Numbered list" disabled={sourceMode} />
        <ToolbarButton onClick={onLink} isActive={editor.isActive('link')} label="Link" disabled={sourceMode} />
        <ToolbarButton onClick={sourceMode ? exitSourceMode : enterSourceMode} isActive={sourceMode} label="HTML" />
      </div>
      {sourceMode ? (
        <textarea
          className="wysiwyg-editor__source"
          aria-label="HTML source"
          value={sourceHtml}
          onChange={onSourceChange}
          onBlur={() => onBlur && onBlur()}
          rows="8"
        />
      ) : (
        <EditorContent editor={editor} />
      )}
    </div>
  );
};

WysiwygEditor.propTypes = {
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  onFocus: PropTypes.func,
  onBlur: PropTypes.func,
  invalid: PropTypes.bool,
};

export default WysiwygEditor;
