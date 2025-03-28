import React from 'react';
import PropTypes from 'prop-types';

export const FullHistoryRow = ({ student, course }) => {
  const editLinks = course.wikis.length > 1
  ? student.global_contribution_url
  : student.contribution_url;

  return (
    <tr key={`${student.id}-contribs`}>
      <td colSpan="7" className="text-center">
        <p><a href={editLinks} target="_blank">{I18n.t('users.contributions_history_full')}</a></p>
      </td>
    </tr>
  );
};

FullHistoryRow.propTypes = {
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    contribution_url: PropTypes.string.isRequired,
    global_contribution_url: PropTypes.string.isRequired
  }).isRequired
};

export default FullHistoryRow;
