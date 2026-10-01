import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import CourseUtils from '../../utils/course_utils.js';
import { getCanViewAsStudent, getIsViewingAsStudent } from '../../selectors';
import { enterStudentView, exitStudentView } from '../../actions/student_view_actions';

// Lets an instructor switch the course page to how an enrolled student sees it.
// It's offered on the Home tab; once on, it shows on every tab so it can be
// switched off from wherever the instructor is.
const StudentViewToggle = ({ courseSlug, location }) => {
  const dispatch = useDispatch();
  const canViewAsStudent = useSelector(getCanViewAsStudent);
  const active = useSelector(getIsViewingAsStudent);

  if (!canViewAsStudent) { return null; }
  if (!active && !CourseUtils.onHomeTab(location)) { return null; }

  const toggle = () => dispatch(active ? exitStudentView(courseSlug) : enterStudentView(courseSlug));

  return (
    <div className="student-view-toggle">
      <button
        type="button"
        className={`button ${active ? 'dark' : 'border'}`}
        aria-pressed={active}
        onClick={toggle}
      >
        {I18n.t('courses.view_as_student')}
      </button>
    </div>
  );
};

StudentViewToggle.propTypes = {
  courseSlug: PropTypes.string.isRequired,
  location: PropTypes.object.isRequired
};

export default StudentViewToggle;
