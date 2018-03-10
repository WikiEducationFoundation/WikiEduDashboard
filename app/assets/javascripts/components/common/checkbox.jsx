import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc.jsx';

const Checkbox = createReactClass({
  displayName: 'Checkbox',

  propTypes: {
    container_class: PropTypes.string,
    label: PropTypes.string,
    value: PropTypes.bool,
    editable: PropTypes.bool
  },

  onCheckboxChange(e) {
    e.target.value = e.target.checked;
    return this.props.onChange(e);
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
          checked={this.props.value}
          onChange={this.onCheckboxChange}
          disabled={!this.props.editable}
        />
      </p>
    );
  }
});

export default InputHOC(Checkbox);
