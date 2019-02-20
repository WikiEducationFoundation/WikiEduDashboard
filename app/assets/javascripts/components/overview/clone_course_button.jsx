import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { cloneCourse } from '../../actions/course_creation_actions.js';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { updateCourse } from '../../actions/course_actions.js';

CloneCourseButton.propTypes = {
  courseId: PropTypes.number.isRequired,
  cloneCourse: PropTypes.func.isRequired,
  initiateConfirm: PropTypes.func.isRequired,
  updateCourse: PropTypes.func.isRequired
};

export function CloneCourseButton(props) {
  return (
    <a onClick={onClickConfirmation(props)} className="button">
      {I18n.t('courses.creator.clone_this')}
    </a>
  );
}

function onClickConfirmation(props) {
  return () => {
    const clone = () => {
      props.cloneCourse(props.courseId).then(({ data }) => {
        const course = data.course;
        props.updateCourse(course);
        window.location = `/courses/${course.slug}`;
      });
    };
    props.initiateConfirm('Are you sure you want to clone this course?', clone);
  };
}

const mapDispatchToProps = {
  cloneCourse,
  initiateConfirm,
  updateCourse
};

const connectorFn = connect(null, mapDispatchToProps);
export default connectorFn(CloneCourseButton);
