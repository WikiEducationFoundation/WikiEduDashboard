import React from 'react';
import { connect } from 'react-redux';
import { getInstructorUsers } from '../../selectors';
import InlineUsers from './inline_users.jsx';
import CourseUtils from '../../utils/course_utils.js';
import { INSTRUCTOR_ROLE } from '../../constants';

const Instructors = (props) => {
  return (
    <InlineUsers {...props} users={props.instructors} role={INSTRUCTOR_ROLE} title={CourseUtils.i18n('instructors', props.course.string_prefix)} />
  );
};

const mapStateToProps = state => ({
  instructors: getInstructorUsers(state)
});

export default connect(mapStateToProps)(Instructors);
