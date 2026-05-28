import React from 'react';
import PropTypes from 'prop-types';
import { onEnterOrSpace } from '../../../utils/keyboard_handlers';

const OverviewStatsTab = ({ id, title, active, onClick }) => {
  const isActive = (active) ? ' active' : '';
  const tabClass = `tab${isActive}`;
  const tabId = `tab-${id}`;
  return (
    <div
      role="tab"
      tabIndex={0}
      aria-selected={active}
      className={tabClass}
      onClick={onClick}
      onKeyDown={onEnterOrSpace(onClick)}
      id={tabId}
    >
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
