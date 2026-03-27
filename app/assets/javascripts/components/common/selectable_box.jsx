import React from 'react';

const SelectableBox = ({ onClick, heading, description, style, selected }) => {
  return (
    <div
      key={heading}
      onClick={onClick}
      className={`program-description ${selected ? 'selected' : ''}`}
      style={style}
      role="checkbox"
      aria-checked={selected}
      tabIndex="0"
      onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') onClick(); }}
    >
      {selected && <img src="/assets/images/check.svg" alt="selected" className="checkbox-image" />}
      <h4><strong>{heading}</strong></h4>
      {description.split('\n').map((paragraph, i) => paragraph && <p key={i}>{paragraph}</p>)}
    </div>
  );
};

SelectableBox.propTypes = {
  onClick: PropTypes.func.isRequired,
  heading: PropTypes.string.isRequired,
  description: PropTypes.string,
  style: PropTypes.object,
  selected: PropTypes.bool
};

export default SelectableBox;
