import React from 'react';
import { onEnterOrSpace } from '../../utils/keyboard_handlers';

const SelectableBox = ({ onClick, heading, description, style, selected }) => {
  return (
    <div
      key={heading}
      role="button"
      tabIndex={0}
      onClick={onClick}
      onKeyDown={onEnterOrSpace(onClick)}
      aria-pressed={selected}
      className={`program-description ${selected ? 'selected' : ''}`}
      style={style}
    >
      {selected && <img src="/assets/images/check.svg" alt="checkbox" className="checkbox-image" />}
      <h4><strong>{heading}</strong></h4>
      {description.split('\n').map((paragraph, i) => paragraph && <p key={i}>{paragraph}</p>)}
    </div>
  );
};

export default SelectableBox;
