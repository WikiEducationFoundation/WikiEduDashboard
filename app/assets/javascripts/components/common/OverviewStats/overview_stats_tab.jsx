import React from 'react';
import PropTypes from 'prop-types';

const OverviewStatsTab = ({ id, title, active, onClick }) => {
  const isActive = (active) ? ' active' : '';
  const tabClass = `tab${isActive}`;
  const tabId = `tab-${id}`;
  return (
    <div className={tabClass} onClick={onClick} id={tabId}>
      <p>{title}</p>
    </div>
  );
};

OverviewStatsTab.propTypes = {
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
  active: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired
};

export default OverviewStatsTab;
