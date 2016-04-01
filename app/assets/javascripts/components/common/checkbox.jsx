import React from 'react';
import InputMixin from '../../mixins/input_mixin.cjsx';

const Checkbox = React.createClass({
  displayName: 'Checkbox',

  propTypes: {
    container_class: React.PropTypes.string,
    label: React.PropTypes.string,
    value: React.PropTypes.bool,
    editable: React.PropTypes.bool
  },

  mixins: [InputMixin],

  getInitialState() {
    return { value: this.props.value };
  },

  onCheckboxChange(e) {
    e.target.value = e.target.checked;
    return this.onChange(e);
  },

  render() {
    let label;
    if (this.props.label) {
      label = (
        <span>{`${this.props.label}: `}</span>
      );
    }
    return (
      <p className={this.props.container_class}>
        {label}
        <input
          type="checkbox"
          checked={this.state.value}
          onChange={this.onCheckboxChange}
          disabled={!this.props.editable}
        />
      </p>
    );
  }
});

export default Checkbox;
