import React, { forwardRef } from 'react';
import PropTypes from 'prop-types';

const SearchBar = ({ onClickHandler, placeholder, value, name }, ref) => {
  const onEnter = (e) => {
    if (e.key === 'Enter') {
      onClickHandler();
    }
  };
  return (
    <div className="search-bar" style={{ position: 'relative' }}>
      <input
        type="text"
        name={name}
        placeholder={placeholder}
        ref={ref}
        style={{ width: '100%', position: 'relative' }}
        defaultValue={value}
        onKeyUp={onEnter}
        aria-label={placeholder}
      />
      <button
        className="icon-search"
        onClick={onClickHandler}
        style={{ position: 'absolute', top: '50%', right: '15px', transform: 'translate(0%, -50%)' }}
        aria-label={I18n.t('courses.search')}
      />
    </div>
  );
};

SearchBar.propTypes = {
  onClickHandler: PropTypes.func.isRequired,
  placeholder: PropTypes.string,
  value: PropTypes.string,
  name: PropTypes.string
};

export default forwardRef(SearchBar);
