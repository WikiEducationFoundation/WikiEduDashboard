import React from 'react';
const md = require('../../utils/markdown_it.js').default();
import InputMixin from '../../mixins/input_mixin.cjsx';
import TrixEditor from 'react-trix';

const TextAreaInput = React.createClass({
  displayName: 'TextAreaInput',

  propTypes: {
    onChange: React.PropTypes.func,
    onFocus: React.PropTypes.func,
    onBlur: React.PropTypes.func,
    value: React.PropTypes.string,
    value_key: React.PropTypes.string,
    editable: React.PropTypes.bool,
    id: React.PropTypes.string,
    focus: React.PropTypes.bool,
    placeholder: React.PropTypes.string,
    autoExpand: React.PropTypes.bool,
    wysiwyg: React.PropTypes.bool,
    markdown: React.PropTypes.bool,
    rows: React.PropTypes.string,
    className: React.PropTypes.string
  },

  mixins: [InputMixin],

  getInitialState() {
    return { value: this.props.value };
  },

  _handleChange(e) {
    this.onChange(e);
    return this.setState({ value: e.target.innerHTML });
  },

  render() {
    let inputElement;
    let rawHtml;

    // ////////////
    // Edit mode //
    // ////////////
    if (this.props.editable) {
      // Use Trix if props.wysiwyg, otherwise, use a basic textarea.
      if (this.props.wysiwyg) {
        inputElement = (
          <TrixEditor
            value={this.state.value}
            onChange={this._handleChange}
          />
        );
      } else {
        inputElement = (
          <textarea
            ref="input"
            id={this.state.id}
            rows={this.props.rows || '8'}
            value={this.state.value}
            onChange={this.onChange}
            autoFocus={this.props.focus}
            onFocus={this.focus}
            onBlur={this.blur}
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
