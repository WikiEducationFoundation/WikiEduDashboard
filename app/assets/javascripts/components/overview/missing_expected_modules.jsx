import React from 'react';
import PropTypes from 'prop-types';

// Admin-facing warning listing expected training modules and exercises that
// are missing from the timeline. Each entry is the list of modules that would
// satisfy one expectation; any one of them will do.
const MissingExpectedModules = ({ missingModules }) => {
  if (!missingModules || missingModules.length === 0) { return null; }

  return (
    <div className="missing-expected-modules">
      <p>{I18n.t('courses.missing_expected_modules')}</p>
      <ul>
        {missingModules.map(names => (
          <li key={names.join('|')}>{names.join(' / ')}</li>
        ))}
      </ul>
    </div>
  );
};

MissingExpectedModules.propTypes = {
  missingModules: PropTypes.arrayOf(PropTypes.arrayOf(PropTypes.string))
};

export default MissingExpectedModules;
