import React from 'react';

const SelectableBox = ({ onClick, key, heading, description, style }) => {
  return (
    <div key={key} onClick={onClick} className="program-description" style={style}>
      <h4><strong>{heading}</strong></h4>
      <p>
        {description}
      </p>
    </div>
  );
};

export default SelectableBox;
