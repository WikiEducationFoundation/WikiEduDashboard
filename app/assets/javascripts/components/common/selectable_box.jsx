import React from 'react';
import checkboxSvg from '../../../svg/check.svg';

const SelectableBox = ({ onClick, heading, description, style, selected }) => {
  return (
    <div key={heading} onClick={onClick} className={`program-description ${selected ? 'selected' : ''}`} style={style}>
      {selected && <img src={checkboxSvg} alt="checkbox" className="checkbox-image" />}
      <h4><strong>{heading}</strong></h4>
      <p>
        {description}
      </p>
    </div>
  );
};

export default SelectableBox;
