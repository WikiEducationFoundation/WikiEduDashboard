import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

const CourseDetails = ({ courses, username }) => {
  const labelKey = Features.wikiEd ? 'courses.view_page' : 'courses_generic.view_page';
  const elements = courses.map((course) => {
    return (
      <a className="course" key={`${course.course_slug}-${course.user_role}`} href={`/courses/${course.course_slug}`}>
        <div className="button border">{I18n.t(labelKey)}</div>
        <div className="course-title">{course.course_title}</div>
        <div className="course-details">
          <div className="col">
            <div className="course-details_title">{I18n.t('courses.school')}</div>
            <div className="course-details_value">{course.course_school}</div>
          </div>
          <div className="col">
            <div className="course-details_title">{I18n.t('courses.term')}</div>
            <div className="course-details_value">{course.course_term}</div>
          </div>
          <div className="col">
            <div className="course-details_title">{I18n.t('courses.students_count')}</div>
            <div className="course-details_value">{course.user_count}</div>
          </div>
          <div className="col">
            <div className="course-details_title">{I18n.t('courses.user_role')}</div>
            <div className="course-details_value">{course.user_role}</div>
          </div>
        </div>
      </a>
    );
  });

  return (
    <div id="course-details">
      <div className="user-articles__navigation">
        <Link to={`/users/${username}`} className="button ghost small">
          ← {I18n.t('users.back_to_profile') || 'Back to Profile'}
        </Link>
      </div>
      <h3>{I18n.t('courses.course_details')}</h3>
      {elements}
    </div>
  );
};

CourseDetails.propTypes = {
  courses: PropTypes.array,
  username: PropTypes.string
};

export default CourseDetails;