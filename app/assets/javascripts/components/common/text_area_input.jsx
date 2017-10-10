import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });
import InputMixin from '../../mixins/input_mixin.js';
import { TrixEditor } from 'react-trix';

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
    wysiwyg: PropTypes.bool, // use Trix editor instead of plain text
    markdown: PropTypes.bool, // render value as Markdown when in read mode
    className: PropTypes.string
  },

  mixins: [InputMixin],

  getInitialState() {
    return { value: this.props.value };
  },

  // react-trix passes html, text to the onChange handler.
  _handleTrixChange(html) {
    const e = { target: { value: html } };
    this.onChange(e);
    return this.setState({ value: html });
  },

  render() {
    let inputElement;
    let rawHtml;

    // ////////////
    // Edit mode //
    // ////////////
    if (this.props.editable) {
      let inputClass;
      if (this.state.invalid) {
        inputClass = 'invalid';
      }

      // Use Trix if props.wysiwyg, otherwise, use a basic textarea.
      if (this.props.wysiwyg) {
        inputElement = (
          <TrixEditor
            value={this.state.value}
            onChange={this._handleTrixChange}
            className={inputClass}
          />
        );
      } else {
        inputElement = (
          <textarea
            className={inputClass}
            id={this.state.id}
            rows={this.props.rows || '8'}
            value={this.state.value || ''}
            onChange={this.onChange}
            autoFocus={this.props.focus}
            onFocus={this.focus}
            onBlur={this.blur}
            maxLength="30000"
            placeholder={this.props.placeholder}
          />
        );
      }

      if (this.props.autoExpand) {
        return (
          <div className="expandingArea active">
            <pre><span>{this.state.value}</span><br /></pre>
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

export default TextAreaInput;
