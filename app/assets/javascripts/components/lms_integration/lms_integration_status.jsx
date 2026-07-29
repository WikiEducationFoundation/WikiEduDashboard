import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import request from '../../utils/request';
import StaffView from './staff_view.jsx';
import StudentView from './student_view.jsx';

// Sidebar panel that surfaces LMS-integration status on a bound
// course. Self-gating: unless the integration is globally enabled AND
// `course.flags.canvas_integration` is set, returns null without firing
// any network calls — non-LMS courses pay nothing, and a disabled
// integration doesn't even ask. When both hold, fetches the role-scoped
// payload from /lms_integration_status.json (which re-checks the gate
// and the binding server-side) and dispatches to the matching subview.
const isLinked = course => Boolean(Features.canvasIntegration && course?.flags?.canvas_integration);

const LmsIntegrationStatus = ({ course }) => {
  const [status, setStatus] = useState(null);

  useEffect(() => {
    if (!isLinked(course)) return;
    request(`/courses/${course.slug}/lms_integration_status.json`)
      .then(response => response.json())
      .then(setStatus)
      .catch(() => setStatus({ bound: false }));
  }, [course?.slug, course?.flags?.canvas_integration]);

  if (!isLinked(course)) return null;
  if (!status || status.bound === false) return null;

  // Payload shape discriminates role:
  //   - `my_linked` present => student variant
  //   - `course_url` present without `my_linked` => instructor
  //   - neither => admin (no Canvas access, no link)
  if ('my_linked' in status) return <StudentView status={status} />;
  return <StaffView status={status} />;
};

LmsIntegrationStatus.propTypes = {
  course: PropTypes.shape({
    slug: PropTypes.string,
    flags: PropTypes.object
  }).isRequired
};

export default LmsIntegrationStatus;
