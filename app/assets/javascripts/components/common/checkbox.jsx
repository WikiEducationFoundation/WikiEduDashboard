import React from 'react';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc.jsx';

const Checkbox = ({ container_class, label, value, editable, onChange }) => {
  const onCheckboxChange = (e) => {
    e.target.value = e.target.checked;
    onChange(e);
  };

  let labelElement = null;
  if (label) {
    labelElement = <span>{`${label}: `}</span>;
  }

  return (
    <p className={container_class}>
      {labelElement}
      <input
        type="checkbox"
        checked={value}
        onChange={onCheckboxChange}
        disabled={!editable}
      />
    </p>
  );
};

Checkbox.propTypes = {
  container_class: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.bool,
  editable: PropTypes.bool,
  onChange: PropTypes.func.isRequired,
};

export default InputHOC(Checkbox);
