import React from 'react';
import InputMixin from '../../mixins/input_mixin.js';
import Conditional from '../high_order/conditional.jsx';

const TextInput = React.createClass({
  displayName: 'TextInput',

  propTypes: {
    value: React.PropTypes.string,
    value_key: React.PropTypes.string,
    editable: React.PropTypes.bool,
    label: React.PropTypes.string,
    placeholder: React.PropTypes.string,
    spacer: React.PropTypes.string,
    valueClass: React.PropTypes.string,
    p_tag_classname: React.PropTypes.string,
    inline: React.PropTypes.bool,
    type: React.PropTypes.string,
    max: React.PropTypes.string,
    maxLength: React.PropTypes.string,
    focus: React.PropTypes.func,
    onBlur: React.PropTypes.func,
    onClick: React.PropTypes.func,
    append: React.PropTypes.node
    // validation: Regex used by Conditional
    // required: bool used by Conditional
  },

  mixins: [InputMixin],

  getInitialState() {
    return { value: this.props.value };
  },

  dateChange(date) {
    const value = date ? date.format('YYYY-MM-DD') : '';
    return this.onChange({ target: { value } });
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
      let title;
      let labelClass = '';
      let inputClass = this.props.inline ? ' inline' : '';
      if (this.state.invalid) {
        labelClass += 'red';
        inputClass += 'invalid';
      }

      if (this.props.type === 'number') {
        title = I18n.t('accessibility.number_field');
      }

      const className = `${inputClass} ${this.props.value_key}`;
      // The default maximum length of 75 ensures that the slug field
      // of a course, which combines three TextInput values, will not exceed
      // the maximum string size of 255.
      const maxLength = this.props.maxLength || '75';
      let input = (
        <input
          ref="input"
          className={className}
          id={this.state.id}
          value={this.state.value}
          onChange={this.onChange}
          autoFocus={this.props.focus}
          onFocus={this.focus}
          onBlur={this.blur}
          type={this.props.type || 'text'}
          max={this.props.max}
          maxLength={maxLength}
          placeholder={this.props.placeholder}
          title={title}
          min={0}
        />
      );

      return (
        <div className="form-group">
          <label htmlFor={this.state.id} className={labelClass}>{label}</label>
          {input}
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

export default Conditional(TextInput);
