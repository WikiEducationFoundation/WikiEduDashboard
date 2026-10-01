import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Navigate, Route, Routes, useParams } from 'react-router-dom';
import Loading from '@components/common/loading.jsx';
import { fetchAssignmentProgress } from './AssignmentProgressAPI';
import AssignmentList from './AssignmentList';
import ArticlePanel from './ArticlePanel';
import AssignmentView from './AssignmentView';

// The summary behind the article panel and the list, fetched each time they're
// shown so it reflects progress made since. An assignment's per-student rows
// are fetched when first opened and kept for reopening.
const AssignmentSummary = ({ course, tabPath }) => {
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);
  const [itemData, setItemData] = useState({});

  const loadItem = (key) => {
    fetchAssignmentProgress(course.slug, key)
      .then(result => setItemData(loaded => ({ ...loaded, [key]: result })))
      .catch(() => setItemData(loaded => ({ ...loaded, [key]: { failed: true } })));
  };

  useEffect(() => {
    fetchAssignmentProgress(course.slug).then(setData).catch(() => setFailed(true));
  }, [course.slug]);

  if (failed) { return <p role="alert">{I18n.t('system_stats.errors.fetch_failed')}</p>; }
  if (!data) { return <Loading />; }
  return (
    <>
      <ArticlePanel data={data} itemData={itemData.article} loadItem={loadItem} tabPath={tabPath} />
      <AssignmentList data={data} itemData={itemData} loadItem={loadItem} tabPath={tabPath} />
    </>
  );
};

AssignmentSummary.propTypes = {
  course: PropTypes.shape({ slug: PropTypes.string.isRequired }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

// An assignment's own URL opens its row in the list; the assigned article's
// opens its panel's student list.
const OpenInList = ({ tabPath }) => {
  const { itemKey } = useParams();
  const params = itemKey === 'article' ? { students: '1' } : { open: itemKey };
  return <Navigate replace to={`${tabPath}?${new URLSearchParams(params)}`} />;
};

OpenInList.propTypes = { tabPath: PropTypes.string.isRequired };

// The instructor-facing Assignments tab: class-wide progress on everything the
// Dashboard tracks (trainings, exercises, article work, peer reviews), each
// opening into its students' statuses, and a one-student-at-a-time grader.
const AssignmentsTabHandler = ({ course }) => {
  if (!course.slug) { return <Loading />; }

  const tabPath = `/courses/${course.slug}/assignments`;
  return (
    <div className="assignments-tab">
      <Routes>
        <Route path=":itemKey/:username" element={<AssignmentView course={course} tabPath={tabPath} />} />
        <Route path=":itemKey" element={<OpenInList tabPath={tabPath} />} />
        <Route path="*" element={<AssignmentSummary course={course} tabPath={tabPath} />} />
      </Routes>
    </div>
  );
};

AssignmentsTabHandler.propTypes = {
  course: PropTypes.shape({ slug: PropTypes.string }).isRequired,
};

export default AssignmentsTabHandler;
