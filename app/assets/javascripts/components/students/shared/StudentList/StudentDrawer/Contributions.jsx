import React from 'react';
import PropTypes from 'prop-types';

// Components
import RevisionRow from './RevisionRow';
import NoRevisionsRow from './NoRevisionsRow';
import FullHistoryRow from './FullHistoryRow';

export const Contributions = ({ course, revisions, selectedIndex, student, wikidataLabels, showDiff }) => {
  const rows = revisions.map((revision, index) => (
    <RevisionRow
      course={course}
      index={index}
      key={index}
      revision={revision}
      revisions={revisions}
      selectedIndex={selectedIndex}
      showDiff={showDiff}
      student={student}
      wikidataLabels={wikidataLabels}
    />
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
