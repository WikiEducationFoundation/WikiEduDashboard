import React, { forwardRef } from 'react';

const SearchBar = ({ onClickHandler, placeholder, value, name }, ref) => {
  const onEnter = (e) => {
    if (e.key === 'Enter') {
      onClickHandler();
    }
  };
  return (
    <>
      <input type="text" name={name} placeholder={placeholder} ref={ref} style={{ width: '100%', position: 'relative' }} defaultValue={value} onKeyUp={onEnter}/>
      <button onClick={onClickHandler}><i className="icon icon-search" /></button>
    </>
  );
};

export default forwardRef(SearchBar);
