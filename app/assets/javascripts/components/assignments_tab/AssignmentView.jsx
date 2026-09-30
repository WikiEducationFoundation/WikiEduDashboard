import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Route, Routes, useParams } from 'react-router-dom';
import Loading from '@components/common/loading.jsx';
import { fetchAssignmentProgress } from './AssignmentProgressAPI';
import AssignmentHeader from './AssignmentHeader';
import AssignmentRoster from './AssignmentRoster';
import AssignmentGrader from './AssignmentGrader';

// One assignment: its per-student rows, shown as the roster or, with a
// student in the path, the grader.
const AssignmentView = ({ course, tabPath }) => {
  const { itemKey } = useParams();
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setData(null);
    setFailed(false);
    fetchAssignmentProgress(course.slug, itemKey).then(setData).catch(() => setFailed(true));
  }, [course.slug, itemKey]);

  if (failed) { return <p role="alert">{I18n.t('system_stats.errors.fetch_failed')}</p>; }
  if (!data) { return <Loading />; }

  const item = data.items.find(candidate => candidate.key === data.item_key);
  const cellsByUser = Object.fromEntries(data.rows.map(cell => [cell.user_id, cell]));
  const itemPath = `${tabPath}/${item.key}`;
  const props = { item, students: data.students, cellsByUser, itemPath };

  return (
    <div className="assignments-tab__assignment">
      <AssignmentHeader item={item} tabPath={tabPath} />
      <Routes>
        <Route path=":username" element={<AssignmentGrader {...props} />} />
        <Route path="*" element={<AssignmentRoster {...props} />} />
      </Routes>
    </div>
  );
};

AssignmentView.propTypes = {
  course: PropTypes.shape({ slug: PropTypes.string.isRequired }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentView;
