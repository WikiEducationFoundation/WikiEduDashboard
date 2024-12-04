import React from 'react';

const SelectableBox = ({ onClick, heading, description, style, selected }) => {
  return (
    <div key={heading} onClick={onClick} className={`program-description ${selected ? 'selected' : ''}`} style={style}>
      {selected && <img src="/assets/images/check.svg" alt="checkbox" className="checkbox-image" />}
      <h4><strong>{heading}</strong></h4>
      {description?.split('\n').map((paragraph, i) => paragraph && <p key={i}>{paragraph}</p>)}
    </div>
  );
};

export default SelectableBox;
