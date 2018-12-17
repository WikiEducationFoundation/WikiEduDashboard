import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Conditional from '../high_order/conditional.jsx';
import InputHOC from '../high_order/input_hoc.jsx';

const BlockTypeSelect = createReactClass({
  displayName: 'BlockTypeSelect',

  propTypes: {
    value: PropTypes.any,
    options: PropTypes.array,
    editable: PropTypes.bool,
  },

  render() {
    const labelClass = 'tooltip-trigger';
    const label = 'Block type:';
    const tooltip = (
      <div className="tooltip dark">
        <p>{I18n.t('timeline.block_type')}</p>
      </div>
          );

    const options = this.props.options.map((option, i) => {
      return <option value={i} key={i}>{option}</option>;
    });

    if (this.props.editable) {
      return (
        <div className="form-group">
          <label htmlFor={this.props.id} className={labelClass}>{label}{tooltip}</label>
          <select
            id={this.props.id}
            value={this.props.value}
            onChange={this.props.onChange}
          >
            {options}
          </select>
        </div>);
    }
    return <span>{this.props.options[this.props.value]}</span>;
  }
}
);

export default Conditional(InputHOC(BlockTypeSelect));
