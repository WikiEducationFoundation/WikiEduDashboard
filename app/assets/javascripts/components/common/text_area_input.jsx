import React from 'react';
const md = require('../../utils/markdown_it.js').default();
import InputMixin from '../../mixins/input_mixin.js';
import { TrixEditor } from 'react-trix';

// This is a flexible text input box. It switches between edit and read mode,
// and can either provide a wysiwyg editor or a plain text editor.
const TextAreaInput = React.createClass({
  displayName: 'TextAreaInput',

  propTypes: {
    onChange: React.PropTypes.func,
    onFocus: React.PropTypes.func,
    onBlur: React.PropTypes.func,
    value: React.PropTypes.string,
    value_key: React.PropTypes.string,
    editable: React.PropTypes.bool, // switch between read and edit mode
    id: React.PropTypes.string,
    focus: React.PropTypes.bool,
    placeholder: React.PropTypes.string,
    autoExpand: React.PropTypes.bool, // start with one line and expand as needed — plain text only
    rows: React.PropTypes.string, // set the number of rows — plain text only
    wysiwyg: React.PropTypes.bool, // use Trix editor instead of plain text
    markdown: React.PropTypes.bool, // render value as Markdown when in read mode
    className: React.PropTypes.string
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
      <div className={this.props.className} dangerouslySetInnerHTML={{ __html: rawHtml }}></div>
    );
  }
}
);

export default TextAreaInput;
