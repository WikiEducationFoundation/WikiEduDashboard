import React from 'react';
import PropTypes from 'prop-types';

// Components
import RevisionRow from './RevisionRow';
import NoRevisionsRow from './NoRevisionsRow';
import FullHistoryRow from './FullHistoryRow';

export const Contributions = ({ revisions, student }) => {
  const rows = revisions.map((revision, index) => (
    <RevisionRow key={index} revision={revision} index={index} />
  ));

  if (rows.length === 0) rows.push(<NoRevisionsRow key="no-revisions" student={student} />);
  rows.push(<FullHistoryRow key="full-history" student={student} />);

  return (
    <table className="table">
      <thead>
        <tr>
          <th>{I18n.t('users.contributions')}</th>
          <th className="desktop-only-tc">{I18n.t('metrics.date_time')}</th>
          <th className="desktop-only-tc">{I18n.t('metrics.char_added')}</th>
          <th className="desktop-only-tc">{I18n.t('metrics.references_count')}</th>
          <th className="desktop-only-tc">{I18n.t('metrics.view')}</th>
          <th className="desktop-only-tc" />
        </tr>
      </thead>
      <tbody>{rows}</tbody>
    </table>
  );
};

Contributions.propTypes = {
  revisions: PropTypes.arrayOf(PropTypes.object).isRequired,
  student: PropTypes.object.isRequired
};

export default Contributions;
