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
  placeholder,
  autoExpand,
  rows,
  wysiwyg,
  markdown,
  className,
  invalid
}) => {
  const [WysiwygEditor, setWysiwygEditor] = useState(null);

  useEffect(() => {
    // Load the rich text editor lazily, and only for signed-in users: anonymous
    // visitors can't edit, and this keeps the editor out of the main bundle.
    if (wysiwyg && Features.user_signed_in && !WysiwygEditor) {
      import('./wysiwyg_editor').then(mod => setWysiwygEditor(() => mod.default));
    }
  }, [wysiwyg, WysiwygEditor]);

  let inputElement;
  let rawHtml;

  // ////////////
  // Edit mode //
  // ////////////
  if (editable) {
    const inputClass = invalid ? 'invalid' : '';

    // Use the wysiwyg editor if props.wysiwyg, otherwise, use a basic textarea.
    if (wysiwyg && WysiwygEditor) {
      inputElement = (
        <WysiwygEditor
          value={value}
          onChange={onChange}
          invalid={invalid}
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
    return <div>{inputElement}</div>;
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
  placeholder: PropTypes.string,
  autoExpand: PropTypes.bool, // start with one line and expand as needed — plain text only
  rows: PropTypes.string, // set the number of rows — plain text only
  wysiwyg: PropTypes.bool, // use rich text editor instead of plain text
  markdown: PropTypes.bool, // render value as Markdown when in read mode
  className: PropTypes.string,
  invalid: PropTypes.bool
};

export default InputHOC(TextAreaInput);
