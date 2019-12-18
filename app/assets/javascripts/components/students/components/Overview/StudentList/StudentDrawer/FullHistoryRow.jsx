import React from 'react';
import PropTypes from 'prop-types';

export const FullHistoryRow = ({ student }) => (
  <tr key={`${student.id}-contribs`}>
    <td colSpan="7" className="text-center">
      <p><a href={student.contribution_url} target="_blank">{I18n.t('users.contributions_history_full')}</a></p>
    </td>
  </tr>
);

FullHistoryRow.propTypes = {
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    contribution_url: PropTypes.string.isRequired
  }).isRequired
};

export default FullHistoryRow;
