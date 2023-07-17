import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ActivityTable from './activity_table.jsx';
import { fetchRecentEdits, sortRecentEdits } from '../../actions/recent_edits_actions.js';

const NO_ACTIVITY_MESSAGE = I18n.t('recent_activity.no_edits');

const HEADERS = [
  { title: I18n.t('recent_activity.article_title'), key: 'title' },
  { title: I18n.t('recent_activity.revision_score'), key: 'revision_score', style: { width: 180 } },
  { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
  { title: I18n.t('recent_activity.revision_datetime'), key: 'datetime', style: { width: 200 } },
];

const RecentEditsHandler = () => {
  const myCoursesRef = useRef(null);

  const dispatch = useDispatch();
  const revisions = useSelector(state => state.recentEdits.revisions);
  const loading = useSelector(state => state.recentEdits.loading);

  useEffect(() => {
    dispatch(fetchRecentEdits());
  }, []);

  const setCourseScope = (e) => {
    const scoped = e.target.checked;
    dispatch(fetchRecentEdits({ scoped }));
  };

  return (
    <div>
      <label>
        <input ref={myCoursesRef} type="checkbox" onChange={setCourseScope} />
        {I18n.t('recent_activity.show_courses')}
      </label>
      <ActivityTable
        loading={loading}
        activity={revisions}
        headers={HEADERS}
        noActivityMessage={NO_ACTIVITY_MESSAGE}
        onSort={dataSortKey => dispatch(sortRecentEdits(dataSortKey))}
      />
    </div>
  );
};

RecentEditsHandler.propTypes = {
  fetchRecentEdits: PropTypes.func,
  sortRecentEdits: PropTypes.func,
  revisions: PropTypes.array,
  loading: PropTypes.bool
};

export default (RecentEditsHandler);
