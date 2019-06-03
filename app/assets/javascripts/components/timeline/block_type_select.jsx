import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Conditional from '../high_order/conditional.jsx';
import InputHOC from '../high_order/input_hoc.jsx';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const KINDS = ['In Class', 'Assignment', 'Milestone', 'Custom', 'Handouts', 'Resources'];

const BlockTypeSelect = createReactClass({
  displayName: 'BlockTypeSelect',

  propTypes: {
    value: PropTypes.any,
    editable: PropTypes.bool,
  },

  handleClick(selectedOption) {
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

    const options = KINDS.map((option, i) => {
      return { value: i, label: option };
    });

    if (this.props.editable) {
      return (
        <div className="react-select_dropdown">
          <div className="form-group">
            <label htmlFor={this.props.id} className={labelClass}>
              {label}
              {tooltip}
            </label>
            <Select
              id={this.props.id}
              value={options.find(option => option.value === this.props.value)}
              onChange={this.handleClick}
              options={options}
              styles={selectStyles}
            />
          </div>
        </div>
      );
    }
    return <span>{KINDS[this.props.value]}</span>;
  }
});

export default Conditional(InputHOC(BlockTypeSelect));
