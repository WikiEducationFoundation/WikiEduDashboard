import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CreatableSelect from 'react-select/creatable';
import { UPDATE_PAGEPILE_IDS } from '../../../constants/scoping_methods';

const PAGEPILE_URL_PATTERN = /https:\/\/pagepile.toolforge.org\/api.php\?id=(\d+).+/;
const PagePileScoping = () => {
  const [inputValue, setInputValue] = useState('');
  const pagePileIds = useSelector(state => state.scopingMethods.pagepile.ids);

  const dispatch = useDispatch();

  const handleAddId = (value) => {
    if (isNaN(value)) {
      return;
    }
    dispatch({
      type: UPDATE_PAGEPILE_IDS,
      ids: pagePileIds.concat({
        label: value,
        value: value,
      }),
    });
    setInputValue('');
  };

  const handleKeyDown = async (event) => {
    if (!inputValue) return;
    switch (event.key) {
      case 'Enter':
      case 'Tab':
      case ',':
        handleAddId(inputValue);
        event.preventDefault();
        break;
      default:
    }
  };

  const onChangeHandler = (newValue, data) => {
    if (data.action !== 'input-change') return;
    if (!newValue) {
      setInputValue('');
      return;
    }
    if (newValue.match(PAGEPILE_URL_PATTERN)) {
      const pagepileID = newValue.match(PAGEPILE_URL_PATTERN)[1];
      dispatch({
        type: UPDATE_PAGEPILE_IDS,
        ids: pagePileIds.concat({
          label: pagepileID,
          value: pagepileID,
        }),
      });
      setInputValue('');
    } else if (!isNaN(newValue)) {
      setInputValue(newValue);
    }
  };

  const onBlurHandler = () => {
    if (!inputValue) {
      setInputValue('');
      return;
    }
    handleAddId(inputValue);
  };

  return (
    <div className="scoping-method-petscan form-group">
      <label htmlFor="pagepile-ids">Enter PagePile IDs/URLs</label>
      <CreatableSelect
        inputValue={inputValue}
        isClearable
        isMulti
        menuIsOpen={false}
        onChange={ids => dispatch({ type: UPDATE_PAGEPILE_IDS, ids })}
        onInputChange={onChangeHandler}
        onKeyDown={handleKeyDown}
        placeholder="Type something and press enter. Or enter a comma-separated list"
        value={pagePileIds}
        className="react-select-container"
        id="pagepile-ids"
        onBlur={onBlurHandler}
      />
    </div>
  );
};

export default PagePileScoping;
