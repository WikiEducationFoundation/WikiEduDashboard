import React from 'react';
import Select from 'react-select';
import sortSelectStyles from '../../styles/sort_select';

// This is a component which creates a dropdown to sort a list
// "keys" is expected to be in the same format as "app/assets/javascripts/components/common/list.jsx"
// "sortSelect" is a function which is called when a new option is selected
//  with the name of the selected property
const DropdownSortSelect = ({ keys, sortSelect }) => {
  const onChangeHandler = (event) => {
    sortSelect(event.value);
  };
  const options = Object.entries(keys).map(([key, value]) => {
    return { value: key, label: value.label };
  });
  return (
    <div className="sort-container">
      <Select
        name="sorts"
        onChange={onChangeHandler}
        options={options}
        styles={sortSelectStyles}
      />
    </div>
  );
};

export default DropdownSortSelect;
