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
  const backParams = new URLSearchParams({ open: item.key });
  if (searchParams.get('filter')) { backParams.set('filter', searchParams.get('filter')); }

  return (
    <div className="assignments-tab__assignment">
      <AssignmentHeader item={item} backPath={`${tabPath}?${backParams}`} />
      <AssignmentGrader
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
