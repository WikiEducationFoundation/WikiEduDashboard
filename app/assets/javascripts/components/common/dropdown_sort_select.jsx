import React from 'react';

// This is a component which creates a dropdown to sort a list
// "keys" is expected to be in the same format as "app/assets/javascripts/components/common/list.jsx"
// "sortSelect" is a function which is called when a new option is selected
//  with the name of the selected property
const DropdownSortSelect = ({ keys, sortSelect }) => {
  const onChangeHandler = (event) => {
    sortSelect(event.target.value);
  };
  return (
    <div className="sort-select">
      <select className="sorts" name="sorts" onChange={onChangeHandler}>
        {Object.entries(keys).map(([key, value]) =>
          <option key={key} value={key}>{value.label}</option>
      )}
      </select>
    </div>
  );
};

export default DropdownSortSelect;
