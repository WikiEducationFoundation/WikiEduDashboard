import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ActivityTable from './activity_table.jsx';
import { fetchSuspectedPlagiarism, sortSuspectedPlagiarism } from '../../actions/suspected_plagiarism_actions.js';

const HEADERS = [
  { title: I18n.t('recent_activity.article_title'), key: 'title' },
  { title: I18n.t('recent_activity.plagiarism_report'), key: 'report_url', style: { width: 180 } },
  { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
  { title: I18n.t('recent_activity.revision_datetime'), key: 'datetime', style: { width: 200 } },
];

const NO_ACTIVITY_MESSAGE = I18n.t('recent_activity.no_plagiarism');

const PlagiarismHandler = () => {
  const myCoursesRef = useRef(null);

  const dispatch = useDispatch();
  const revisions = useSelector(state => state.suspectedPlagiarism.revisions);
  const loading = useSelector(state => state.suspectedPlagiarism.loading);

  useEffect(() => {
    dispatch(fetchSuspectedPlagiarism());
  }, []);

  const setCourseScope = (e) => {
    const scoped = e.target.checked;
    dispatch(fetchSuspectedPlagiarism({ scoped }));
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
        onSort={dataSortKey => dispatch(sortSuspectedPlagiarism(dataSortKey))}
      />
    </div>
  );
};

PlagiarismHandler.propTypes = {
  fetchSuspectedPlagiarism: PropTypes.func,
  revisions: PropTypes.array,
  loading: PropTypes.bool
};

export default (PlagiarismHandler);
