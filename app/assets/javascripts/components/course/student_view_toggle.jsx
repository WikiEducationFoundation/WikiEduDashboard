import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { getIsViewingAsStudent } from '../../selectors';
import { enterStudentView, exitStudentView } from '../../actions/student_view_actions';

// The switch moves when it's used, so the button that was pressed is removed.
// Focus follows it to its new place or, on tabs without the Actions panel, to
// the current tab's link in the course nav.
const refocusAfterMove = () => {
  setTimeout(() => {
    const target = document.querySelector('.student-view-toggle')
      || document.querySelector('.course_navigation nav a.active');
    if (target) { target.focus(); }
  });
};

// Switches the course page between an instructor's view and how an enrolled
// student sees it. The Home tab's Actions panel offers it while it's off; while
// it's on, it sits in the course nav on every tab, so it's easy to switch off.
const StudentViewToggle = ({ courseSlug }) => {
  const dispatch = useDispatch();
  const active = useSelector(getIsViewingAsStudent);

  const toggle = () => {
    dispatch(active ? exitStudentView(courseSlug) : enterStudentView(courseSlug));
    refocusAfterMove();
  };

  return (
    <button
      type="button"
      role="switch"
      aria-checked={active}
      className="student-view-toggle"
      onClick={toggle}
    >
      <span>{I18n.t('courses.view_as_student')}</span>
      <span className="student-view-toggle__track" aria-hidden="true">
        <span className="student-view-toggle__knob" />
      </span>
    </button>
  );
};

StudentViewToggle.propTypes = {
  courseSlug: PropTypes.string.isRequired
};

export default StudentViewToggle;
