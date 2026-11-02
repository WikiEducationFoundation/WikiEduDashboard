import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Navigate, useLocation } from 'react-router-dom';

import Loading from '@components/common/loading.jsx';
import { fetchAssignmentProgress } from '@components/assignments_tab/AssignmentProgressAPI';
import { isClaimVerification } from '@components/assignments_tab/assignmentHelpers';
import InstructorResponses from './InstructorResponses.jsx';

/*
  /verify_claim/responses, where the timeline's "Student responses" link goes.
  In a course with the Assignments tab, responses are graded there, one
  student at a time with everyone's status alongside, so this forwards to
  that tab's grader for the exercise: at the `?student=` given, otherwise at
  the first student. Without the tab — or when it has no item for the
  exercise, which it only tracks while the exercise is on the timeline, or
  when the viewer can't open the tab — it is the list of every submission.
*/
const ResponsesPage = ({ course }) => {
  const student = new URLSearchParams(useLocation().search).get('student');
  // undefined while looking for the grader, null when there isn't one.
  const [graderPath, setGraderPath] = useState(course.assignments_tab_enabled ? undefined : null);

  useEffect(() => {
    if (!course.assignments_tab_enabled) { return; }
    fetchAssignmentProgress(course.slug)
      .then((data) => {
        const item = data.items.find(isClaimVerification);
        const username = student || data.students[0]?.username;
        setGraderPath(item && username
          ? `/courses/${course.slug}/assignments/${item.key}/${encodeURIComponent(username)}`
          : null);
      })
      .catch(() => setGraderPath(null));
  }, [course.slug, course.assignments_tab_enabled, student]);

  if (graderPath === undefined) { return <Loading />; }
  if (graderPath) { return <Navigate replace to={graderPath} />; }
  return <InstructorResponses course={course} />;
};

ResponsesPage.propTypes = {
  course: PropTypes.shape({
    slug: PropTypes.string.isRequired,
    assignments_tab_enabled: PropTypes.bool,
  }).isRequired,
};

export default ResponsesPage;
