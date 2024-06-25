import React from 'react';
import PropTypes from 'prop-types';
import Conditional from '../high_order/conditional.jsx';
import InputHOC from '../high_order/input_hoc.jsx';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const KINDS = ['In Class', 'Assignment', 'Milestone', 'Custom', 'Handouts', 'Resources'];

const BlockTypeSelect = ({ onChange, editable, id, value }) => {
  const handleClick = (selectedOption) => {
    const e = { target: selectedOption };
    onChange(e);
  };

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

  if (editable) {
    return (
      <div className="react-select_dropdown">
        <div className="form-group">
          <label id={`${id}-label`} htmlFor={id} className={labelClass}>
            {label}
            {tooltip}
          </label>
          <Select
            id={id}
            value={options.find(option => option.value === value)}
            onChange={handleClick}
            options={options}
            styles={selectStyles}
            aria-labelledby={`${id}-label`}
          />
        </div>
      </div>
    );
  }
  return <span>{KINDS[value]}</span>;
};


BlockTypeSelect.propTypes = {
  value: PropTypes.any,
  editable: PropTypes.bool,
};

export default Conditional(InputHOC(BlockTypeSelect));
