import React from 'react';
import PropTypes from 'prop-types';

const InfoStats = ({ info }) => {
  let iStats;

  if (typeof info === 'string') {
      iStats = (
        <p>{info}</p>);
  } else {
  iStats = (info.map((x) => {
        return (
          <div key={`${x[1]}`}>
            <h4 className="stat-display__value">{x[0]}</h4>
            <p>{x[1]}</p>
          </div>);
  })
  );
  }

  return (
    <div className="tooltip dark" id="upload-usage">
      {iStats}
    </div>
  );
};

InfoStats.propTypes = {
  info: PropTypes.oneOfType([
    PropTypes.array,
    PropTypes.string
  ])
};

export default InfoStats;
