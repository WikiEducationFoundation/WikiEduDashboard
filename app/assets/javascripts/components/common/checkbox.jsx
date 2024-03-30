import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc.jsx';

const Checkbox = ({ container_class, label, value, editable, onChange }) => {
  const [checked, setChecked] = useState(value);

  useEffect(() => {
    setChecked(value);
  }, [value]);

  const onCheckboxChange = (e) => {
    const newValue = e.target.checked;
    setChecked(newValue);
    onChange({ ...e, target: { ...e.target, value: newValue } });
  };

  return (
    <p className={container_class}>
      {label && <span>{`${label}: `}</span>}
      <input
        type="checkbox"
        checked={checked}
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
