import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/select';

const MultiSelectField = ({ label, options, disabled, selected, setSelectedFilters }) => {
  const [state, setState] = useState({
    removeSelected: true,
    stayOpen: false,
    value: selected,
    rtl: false,
  });

  useEffect(() => {
    if (selected.length !== state.value.length) {
      setState(prevState => ({
        ...prevState,
        value: selected
      }));
    }
  }, [selected]);

  const handleSelectChange = (newValue) => {
    setState(prevState => ({
      ...prevState,
      value: newValue
    }));
    setSelectedFilters(newValue || []);
  };

  return (
    <div className="section">
      <Select
        closeOnSelect={!state.stayOpen}
        isDisabled={disabled || false}
        isMulti
        onChange={handleSelectChange}
        options={options}
        placeholder={label}
        removeSelected={state.removeSelected}
        rtl={state.rtl}
        simpleValue
        value={state.value}
        styles={selectStyles}
      />
    </div>
  );
};

MultiSelectField.propTypes = {
  label: PropTypes.string,
  options: PropTypes.array,
  disabled: PropTypes.bool,
  selected: PropTypes.array,
  setSelectedFilters: PropTypes.func.isRequired,
};

export default MultiSelectField;
