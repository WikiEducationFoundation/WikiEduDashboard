import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Conditional from '../high_order/conditional.jsx';
import InputMixin from '../../mixins/input_mixin.js';

const BlockTypeSelect = createReactClass({
  displayName: 'BlockTypeSelect',

  propTypes: {
    value: PropTypes.any,
    options: PropTypes.array,
    editable: PropTypes.bool,
  },

  mixins: [InputMixin],
  getInitialState() {
    return { value: this.props.value };
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
      return (<div className="form-group">
        <label htmlFor={this.state.id} className={labelClass}>{label}{tooltip}</label>
        <select
          id={this.state.id}
          value={this.state.value}
          onChange={this.onChange}
        >
          {options}
        </select>
      </div>);
    }
    return <span>{this.props.options[this.props.value]}</span>;
  }
}
);

export default Conditional(BlockTypeSelect);
