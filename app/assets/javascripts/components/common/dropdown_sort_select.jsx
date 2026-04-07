import React from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import sortSelectStyles from '../../styles/sort_select';

// This is a component which creates a dropdown to sort a list
// "keys" is expected to be in the same format as "app/assets/javascripts/components/common/list.jsx"
// "sortSelect" is a function which is called when a new option is selected
//  with the name of the selected property
const DropdownSortSelect = ({ keys, sortSelect }) => {
  const onChangeHandler = (selectedOption) => {
    if (selectedOption && selectedOption.value) {
      sortSelect(selectedOption.value);
    }
  };

  const options = Object.entries(keys)
    .filter(([, value]) => value.sortable !== false)
    .map(([key, value]) => {
      return { value: key, label: value.label };
    });

  const selectedKey = Object.keys(keys).find(key => keys[key].order);

  let placeholderNode = 'Sort...';
  if (selectedKey && keys[selectedKey]) {
    const orderIndicator = keys[selectedKey].order === 'asc' ? ' ▲' : ' ▼';
    placeholderNode = (
      <span>
        {keys[selectedKey].label} {orderIndicator}
      </span>
    );
  }

  return (
    <div className="sort-container">
      <Select
        name="sorts"
        value={null}
        placeholder={placeholderNode}
        onChange={onChangeHandler}
        options={options}
        styles={sortSelectStyles}
      />
    </div>
  );
};

DropdownSortSelect.propTypes = {
  keys: PropTypes.object.isRequired,
  sortSelect: PropTypes.func.isRequired
};

export default DropdownSortSelect;
