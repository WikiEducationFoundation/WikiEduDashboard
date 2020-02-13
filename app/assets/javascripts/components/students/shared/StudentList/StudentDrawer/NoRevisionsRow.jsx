import React from 'react';
import PropTypes from 'prop-types';

export const NoRevisionsRow = ({ student }) => (
  <tr key={`${student.id}-no-revisions`}>
    <td colSpan="7" className="text-center">
      <p>{I18n.t('users.no_revisions')}</p>
    </td>
  </tr>
);

NoRevisionsRow.propTypes = {
  student: PropTypes.shape({
    id: PropTypes.number.isRequired
  }).isRequired
};

export default NoRevisionsRow;
