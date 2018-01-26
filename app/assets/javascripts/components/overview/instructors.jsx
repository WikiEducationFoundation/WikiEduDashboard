import React from 'react';
import { connect } from "react-redux";
import _ from 'lodash';
import { getFiltered } from '../../utils/model_utils';
import InlineUsers from './inline_users.jsx';
import CourseUtils from '../../utils/course_utils.js';

const INSTRUCTOR_ROLE = 1;
const Instructors = props => {
  return (
    <InlineUsers {...props} users={props.instructors} role={INSTRUCTOR_ROLE} title={CourseUtils.i18n('instructors', props.course.string_prefix)} />
  );
};

const mapStateToProps = state => ({
  instructors: _.sortBy(getFiltered(state.users.users, { role: INSTRUCTOR_ROLE }), 'enrolled_at')
});

export default connect(mapStateToProps)(Instructors);
