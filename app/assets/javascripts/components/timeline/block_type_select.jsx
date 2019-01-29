import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Conditional from '../high_order/conditional.jsx';
import InputHOC from '../high_order/input_hoc.jsx';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const BlockTypeSelect = createReactClass({
  displayName: 'BlockTypeSelect',

  propTypes: {
    value: PropTypes.any,
    options: PropTypes.array,
    editable: PropTypes.bool
  },

  getInitialState() {
    const initialState = this.props.options[this.props.value];
    return { selectedOption: { value: this.props.value, label: initialState } };
  },

  handleClick(selectedOption) {
    this.setState({ selectedOption });
    const e = { target: selectedOption };
    this.props.onChange(e);
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
      return { value: i, label: option };
    });

    if (this.props.editable) {
      return (
        <div className="form-group">
          <label htmlFor={this.props.id} className={labelClass}>
            {label}
            {tooltip}
          </label>
          <Select
            id={this.props.id}
            value={options.find(option => option.value === this.state.selectedOption.value)}
            onChange={this.handleClick}
            options={options}
            styles={selectStyles}
          />
        </div>
      );
    }
    return <span>{this.props.options[this.props.value]}</span>;
  }
});

export default Conditional(InputHOC(BlockTypeSelect));
