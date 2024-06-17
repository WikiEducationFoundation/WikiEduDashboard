import { Editor } from '@tinymce/tinymce-react';
import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc';
import markdown_it from '../../utils/markdown_it';

const md = markdown_it({ openLinksExternally: true });

// This is a flexible text input box. It switches between edit and read mode,
// and can either provide a wysiwyg editor or a plain text editor.

const TextAreaInput = ({
  onChange,
  onFocus,
  onBlur,
  value,
  editable,
  id,
  focus,
  placeholder,
  autoExpand,
  rows,
  wysiwyg,
  markdown,
  className,
  clearOnSubmit,
  invalid,
  label,
  spacer
}) => {
  const [tinymceLoaded, setTinymceLoaded] = useState(false);
  const [activeEditor, setActiveEditor] = useState(null);
  const labelContent = label ? `${label}${spacer || ': '}` : undefined;

  useEffect(() => {
    if (wysiwyg) {
      loadTinyMCE();
    }
  }, [wysiwyg]);

  const loadTinyMCE = () => {
    const user_signed_in = Features.user_signed_in; // Ensure Features is accessible
    if (user_signed_in) {
      import('../../tinymce').then(() => {
        setTinymceLoaded(true);
      });
    }
  };

  const handleRichTextEditorChange = (e) => {
    onChange({ target: { value: e } }, e);
  };

  const handleSubmit = () => {
    if (clearOnSubmit) {
      activeEditor.setContent('');
    }
  };

  let inputElement;
  let rawHtml;

  // ////////////
  // Edit mode //
  // ////////////
  if (editable) {
    let inputClass = '';
    if (invalid) {
      inputClass = 'invalid';
    }

    // Use TinyMCE if props.wysiwyg, otherwise, use a basic textarea.
    if (wysiwyg && tinymceLoaded) {
      inputElement = (
        <Editor
          value={value}
          onEditorChange={handleRichTextEditorChange}
          onSubmit={handleSubmit}
          className={inputClass}
          init={{
            setup: editor => setActiveEditor(editor),
            inline: true,
            convert_urls: false,
            plugins: 'lists link code',
            toolbar: [
              'undo redo | styleselect | bold italic',
              'alignleft alignright',
              'bullist numlist outdent indent',
              'link'
            ],
          }}
        />
      );
    } else {
      inputElement = (
        <textarea
          className={inputClass}
          id={id}
          rows={rows || '8'}
          value={value || ''}
          onChange={onChange}
          autoFocus={focus}
          onFocus={onFocus}
          onBlur={onBlur}
          maxLength="30000"
          placeholder={placeholder}
        />
      );
    }

    if (autoExpand) {
      return (
        <div className="expandingArea active">
          <pre><span>{value}</span><br /></pre>
          {inputElement}
        </div>
      );
    }
    return (
      <div className="form-group">
        <label id={`${id}-label`} htmlFor={id} className={invalid ? 'red' : ''}>
          {labelContent}
        </label>
        {inputElement}
      </div>
    );
  }

  // ////////////
  // Read mode //
  // ////////////
  if (markdown) {
    rawHtml = md.render(value || '');
  } else {
    rawHtml = value;
  }

  return <div className={className} dangerouslySetInnerHTML={{ __html: rawHtml }} />;
};

TextAreaInput.propTypes = {
  onChange: PropTypes.func,
  onFocus: PropTypes.func,
  onBlur: PropTypes.func,
  value: PropTypes.string,
  value_key: PropTypes.string,
  editable: PropTypes.bool, // switch between read and edit mode
  id: PropTypes.string,
  focus: PropTypes.bool,
  placeholder: PropTypes.string,
  autoExpand: PropTypes.bool, // start with one line and expand as needed — plain text only
  rows: PropTypes.string, // set the number of rows — plain text only
  wysiwyg: PropTypes.bool, // use rich text editor instead of plain text
  markdown: PropTypes.bool, // render value as Markdown when in read mode
  className: PropTypes.string,
  clearOnSubmit: PropTypes.bool,
  label: PropTypes.string,
  spacer: PropTypes.string,
};

export default InputHOC(TextAreaInput);
