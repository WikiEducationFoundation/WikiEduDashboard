import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc.jsx';
import Conditional from '../high_order/conditional.jsx';

const TextInput = createReactClass({
  displayName: 'TextInput',

  propTypes: {
    value: PropTypes.any,
    value_key: PropTypes.string,
    editable: PropTypes.bool,
    label: PropTypes.string,
    placeholder: PropTypes.string,
    spacer: PropTypes.string,
    valueClass: PropTypes.string,
    p_tag_classname: PropTypes.string,
    inline: PropTypes.bool,
    type: PropTypes.string,
    max: PropTypes.string,
    maxLength: PropTypes.string,
    focus: PropTypes.func,
    onBlur: PropTypes.func,
    onClick: PropTypes.func,
    append: PropTypes.node,
    onKeyDown: PropTypes.func,
    _value: PropTypes.any,
    // validation: Regex used by Conditional
    // required: bool used by Conditional
  },

  onKeyDown(e) {
    if (!this.props.onKeyDown) { return; }
    this.props.onKeyDown(e.keyCode, this.refs.inputbox);
  },

  dateChange(date) {
    const value = date ? date.format('YYYY-MM-DD') : '';
    return this.props.onChange({ target: { value } });
  },

  render() {
    let label;
    const spacer = this.props.spacer || ': ';

    if (this.props.label) {
      label = this.props.label + spacer;
    }

    const value = this.props.value;

    let valueClass = 'text-input-component__value ';
    if (this.props.valueClass) { valueClass += this.props.valueClass; }

    if (this.props.editable) {
      let labelClass = '';
      let inputClass = this.props.inline ? 'inline' : '';
      if (this.props.invalid) {
        labelClass += 'red';
        inputClass += ' invalid';
      }

      let title;
      if (this.props.type === 'number') {
        title = I18n.t('accessibility.number_field');
      }

      const className = `${inputClass} ${this.props.value_key}`;
      // The default maximum length of 75 ensures that the slug field
      // of a course, which combines three TextInput values, will not exceed
      // the maximum string size of 255.
      const maxLength = this.props.maxLength || '75';
      const input = (
        <input
          className={className}
          id={this.props.id}
          value={this.props._value !== undefined ? this.props._value : this.props.value || ''}
          onChange={this.props.onChange}
          autoFocus={this.props.focus}
          onFocus={this.props.onFocus}
          onBlur={this.props.onBlur}
          onKeyDown={this.onKeyDown}
          type={this.props.type || 'text'}
          max={this.props.max}
          maxLength={maxLength}
          placeholder={this.props.placeholder}
          title={title}
          min={0}
          ref="inputbox"
          aria-labelledby={`${this.props.id}-label`}
        />
      );

      return (
        <div className="form-group">
          <label id={`${this.props.id}-label`} htmlFor={this.props.id} className={labelClass}>{label}</label>
          {input}
          {this.props.children}
        </div>
      );
    } else if (this.props.label) {
      return (
        <p className={this.props.p_tag_classname}>
          <span className="text-input-component__label"><strong>{label}</strong></span>
          <span onBlur={this.props.onBlur} onClick={this.props.onClick} className={valueClass}>{value}</span>
          {this.props.append}
        </p>
      );
    }
    return <span>{value}</span>;
  }
}
);

export default Conditional(InputHOC(TextInput));
