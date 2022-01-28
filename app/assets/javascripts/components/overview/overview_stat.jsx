import React from 'react';
import PropTypes from 'prop-types';
import OverviewStatInfo from './overview_stat_info';

const OverviewStat = ({ id, className, stat, statMsg, info }) => {
  return (
    <div className="stat-display__stat tooltip-trigger" id={id}>
      <div className={className}>
        {stat}
        {info && <img src="/assets/images/info.svg" alt="tooltip default logo" />}
      </div>
      <small>{statMsg}</small>
      {
        info
        && <OverviewStatInfo
          info={info}
        />
      }
    </div>
  );
};

OverviewStat.propTypes = {
  id: PropTypes.string.isRequired,
  className: PropTypes.string.isRequired,
  stat: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number
  ]),
  statMsg: PropTypes.string.isRequired,
  info: PropTypes.oneOfType([
    PropTypes.array,
    PropTypes.string
  ]),
};

export default OverviewStat;
