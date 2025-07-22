import React from 'react';
import PropTypes from 'prop-types';
import OverviewStatInfo from './overview_stat_info';

const OverviewStat = ({ id, className, stat, statMsg, renderZero, info, infoId }) => {
  if (!renderZero && stat === 0) { return null; }
  if (stat === undefined) { return null; }

  return (
    <div className="stat-display__stat tooltip-trigger" id={id}>
      <div className={className}>
        {stat}
        {info && < img className="info-img" src="/assets/images/info.svg" alt="tooltip default logo" />}
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
    PropTypes.number,
    PropTypes.string
  ]),
  statMsg: PropTypes.string.isRequired,
  renderZero: PropTypes.bool.isRequired,
  info: PropTypes.oneOfType([
    PropTypes.array,
    // info array is in format [[statNumber1, statDescription1], [statNumber2, statDescription2],...]
    PropTypes.string
  ]),
  infoId: PropTypes.string
};

export default OverviewStat;
