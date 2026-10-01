import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useParams, useSearchParams } from 'react-router-dom';
import Loading from '@components/common/loading.jsx';
import { fetchAssignmentProgress } from './AssignmentProgressAPI';
import AssignmentHeader from './AssignmentHeader';
import AssignmentGrader from './AssignmentGrader';

// The grader for one assignment: its per-student rows, one student at a time.
const AssignmentView = ({ course, tabPath }) => {
  const { itemKey } = useParams();
  const [searchParams] = useSearchParams();
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
  // Back to where the grader was opened from, with its filter still applied:
  // the article panel's student list, or the assignment's open row.
  const backParams = new URLSearchParams(item.kind === 'article' ? { students: '1' } : { open: item.key });
  ['filter', 'missing'].forEach((param) => {
    if (searchParams.get(param)) { backParams.set(param, searchParams.get(param)); }
  });

  return (
    <div className="assignments-tab__assignment">
      <AssignmentGrader
        header={<AssignmentHeader item={item} backPath={`${tabPath}?${backParams}`} />}
        item={item} students={data.students} cellsByUser={cellsByUser}
        itemPath={`${tabPath}/${item.key}`}
      />
    </div>
  );
};

AssignmentView.propTypes = {
  course: PropTypes.shape({ slug: PropTypes.string.isRequired }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentView;
