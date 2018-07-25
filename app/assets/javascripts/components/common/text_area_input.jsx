import { Editor } from '@tinymce/tinymce-react';
import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import InputHOC from '../high_order/input_hoc.jsx';
const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });

// This is a flexible text input box. It switches between edit and read mode,
// and can either provide a wysiwyg editor or a plain text editor.
const TextAreaInput = createReactClass({
  displayName: 'TextAreaInput',

  propTypes: {
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
    className: PropTypes.string
  },

  handleRichTextEditorChange(e) {
    this.props.onChange(
      { target: { value: e.target.getContent() } }
    );
  },

  render() {
    let inputElement;
    let rawHtml;

    // ////////////
    // Edit mode //
    // ////////////
    if (this.props.editable) {
      let inputClass;
      if (this.props.invalid) {
        inputClass = 'invalid';
      }

      // Use TinyMCE if props.wysiwyg, otherwise, use a basic textarea.
      if (this.props.wysiwyg) {
        inputElement = (
          <Editor
            initialValue={this.props.value}
            onChange={this.handleRichTextEditorChange}
            className={inputClass}
            init={{
              height: 250,
              plugins: 'code',
              branding: false,
              inline: true
            }}
          />
        );
      } else {
        inputElement = (
          <textarea
            className={inputClass}
            id={this.props.id}
            rows={this.props.rows || '8'}
            value={this.props.value || ''}
            onChange={this.props.onChange}
            autoFocus={this.props.focus}
            onFocus={this.props.onFocus}
            onBlur={this.props.onBlur}
            maxLength="30000"
            placeholder={this.props.placeholder}
          />
        );
      }

      if (this.props.autoExpand) {
        return (
          <div className="expandingArea active">
            <pre><span>{this.props.value}</span><br /></pre>
            {inputElement}
          </div>
        );
      }
      return (
        <div>
          {inputElement}
        </div>
      );
    }

    // ////////////
    // Read mode //
    // ////////////
    if (this.props.markdown) {
      rawHtml = md.render(this.props.value || '');
    } else {
      rawHtml = this.props.value;
    }
    return (
      <div className={this.props.className} dangerouslySetInnerHTML={{ __html: rawHtml }} />
    );
  }
}
);

export default InputHOC(TextAreaInput);
