import React from 'react';

const SelectableBox = ({ onClick, heading, description, style, selected }) => {
  return (
    <div key={heading} onClick={onClick} className={`program-description ${selected ? 'selected' : ''}`} style={style}>
      <h4><strong>{heading}</strong></h4>
      <p>
        {description}
      </p>
    </div>
  );
};

export default SelectableBox;
