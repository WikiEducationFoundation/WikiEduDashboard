import React from 'react';
import PropTypes from 'prop-types';

const WikiOverviewTabs = ({ id, title, active, onClick }) => {
  const isActive = (active) ? " active" : "";
  const tabClass = "tab" + isActive;
  return(
    <div className={tabClass} onClick={onClick} id={id}>
      <p>{title}</p>
    </div>
  )
};

WikiOverviewTabs.propTypes = {
  id: PropTypes.number,
  title: PropTypes.string,
  active: PropTypes.bool,
  onClick: PropTypes.func
};

export default WikiOverviewTabs;
