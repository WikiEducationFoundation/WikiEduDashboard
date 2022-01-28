import React from 'react';
import PropTypes from 'prop-types';
import OverviewStatInfo from './overview_stat_info';

const OverviewStat = ({ id, className, stat, statMsg, info, infoId }) => {
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
          infoId={infoId}
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
  infoId: PropTypes.string
};

export default OverviewStat;
