import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CreatableSelect from 'react-select/creatable';
import { UPDATE_PAGEPILE_IDS } from '../../../constants/scoping_methods';

const PagePileScoping = () => {
  const [inputValue, setInputValue] = useState('');
  const pagePileIds = useSelector(state => state.scopingMethods.pagepile.ids);

  const dispatch = useDispatch();

  const handleKeyDown = async (event) => {
    if (!inputValue) return;
    switch (event.key) {
      case 'Enter':
      case 'Tab':
        if (isNaN(inputValue)) {
          return;
        }
        dispatch({
          type: UPDATE_PAGEPILE_IDS,
          ids: pagePileIds.concat({
            label: inputValue,
            value: inputValue,
          }),
        });
        setInputValue('');
        event.preventDefault();
        break;
      default:
    }
  };

  return (
    <div className="scoping-method-petscan form-group">
      <label htmlFor="pagepile-ids">Enter PagePile IDs</label>
      <CreatableSelect
        inputValue={inputValue}
        isClearable
        isMulti
        menuIsOpen={false}
        onChange={ids => dispatch({ type: UPDATE_PAGEPILE_IDS, ids })}
        onInputChange={newValue => !isNaN(newValue) && setInputValue(newValue)}
        onKeyDown={handleKeyDown}
        placeholder="Type something and press enter..."
        value={pagePileIds}
        className="react-select-container"
        id="pagepile-ids"
      />
    </div>
  );
};

export default PagePileScoping;
