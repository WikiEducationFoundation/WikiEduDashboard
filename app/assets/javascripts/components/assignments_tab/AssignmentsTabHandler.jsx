import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Route, Routes } from 'react-router-dom';
import Loading from '@components/common/loading.jsx';
import { fetchAssignmentProgress } from './AssignmentProgressAPI';
import AssignmentList from './AssignmentList';
import AssignmentView from './AssignmentView';

// The summary behind the list, fetched each time the list is shown so it
// reflects progress made since.
const AssignmentSummary = ({ course, tabPath }) => {
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    fetchAssignmentProgress(course.slug).then(setData).catch(() => setFailed(true));
  }, [course.slug]);

  if (failed) { return <p role="alert">{I18n.t('system_stats.errors.fetch_failed')}</p>; }
  if (!data) { return <Loading />; }
  return <AssignmentList data={data} tabPath={tabPath} />;
};

AssignmentSummary.propTypes = {
  course: PropTypes.shape({ slug: PropTypes.string.isRequired }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

// The instructor-facing Assignments tab: class-wide progress on everything the
// Dashboard tracks (trainings, exercises, article work, peer reviews), then
// per assignment a roster of students and a one-student-at-a-time grader.
const AssignmentsTabHandler = ({ course }) => {
  if (!course.slug) { return <Loading />; }

  const tabPath = `/courses/${course.slug}/assignments`;
  return (
    <div className="assignments-tab">
      <Routes>
        <Route path=":itemKey/*" element={<AssignmentView course={course} tabPath={tabPath} />} />
        <Route path="*" element={<AssignmentSummary course={course} tabPath={tabPath} />} />
      </Routes>
    </div>
  );
};

AssignmentsTabHandler.propTypes = {
  course: PropTypes.shape({ slug: PropTypes.string }).isRequired,
};

export default AssignmentsTabHandler;
