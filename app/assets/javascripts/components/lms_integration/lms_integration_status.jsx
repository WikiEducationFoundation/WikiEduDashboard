import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import request from '../../utils/request';
import StaffView from './staff_view.jsx';
import StudentView from './student_view.jsx';

// Sidebar panel that surfaces LMS-integration status on a bound
// course. Self-gating: when `course.flags.canvas_integration` is
// absent, returns null without firing any network calls — non-LMS
// courses pay nothing. When the flag is present, fetches the
// role-scoped payload from /lms_integration_status.json and dispatches
// to the matching subview.
const LmsIntegrationStatus = ({ course }) => {
  const [status, setStatus] = useState(null);

  useEffect(() => {
    if (!course?.flags?.canvas_integration) return;
    request(`/courses/${course.slug}/lms_integration_status.json`)
      .then(response => response.json())
      .then(setStatus)
      .catch(() => setStatus({ bound: false }));
  }, [course?.slug, course?.flags?.canvas_integration]);

  if (!course?.flags?.canvas_integration) return null;
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
