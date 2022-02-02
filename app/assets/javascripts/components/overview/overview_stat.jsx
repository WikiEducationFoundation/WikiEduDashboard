import React from 'react';
import PropTypes from 'prop-types';
import OverviewStatInfo from './overview_stat_info';

const OverviewStat = ({ id, className, stat, statMsg, renderZero, info, infoId, renderZeroInfo }) => {
  if (!renderZero && stat === 0) { return null; }

  let isInfo = true;
  if (!info) {
    isInfo = false;
  }
  if (info && typeof info !== 'string' && info.map(i => i[0]).every(i => i === 0) && !renderZeroInfo) {
    isInfo = false;
      }

  return (
    <div className="stat-display__stat tooltip-trigger" id={id}>
      <div className={className}>
        {stat}
        {isInfo && <img src="/assets/images/info.svg" alt="tooltip default logo" />}
      </div>
      <small>{statMsg}</small>
      {
        isInfo
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
    PropTypes.number
  ]),
  statMsg: PropTypes.string.isRequired,
  renderZero: PropTypes.bool.isRequired,
  info: PropTypes.oneOfType([
    PropTypes.array,
    // info array is in format [[statNumber1, statDescription1], [statNumber2, statDescription2],...]
    PropTypes.string
  ]),
  infoId: PropTypes.string,
  renderZeroInfo: PropTypes.bool
};

export default OverviewStat;
