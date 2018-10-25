import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';


const CourseDetails = createReactClass({
  propTypes: {
    courses: PropTypes.array
  },

  render() {
    const elements = this.props.courses.map((course) => {
      return (
        <a className="course" key={`${course.course_slug}-${course.user_role}`} href={`/courses/${course.course_slug}`}>
          <div className="button border">{I18n.t('courses.view_page')}</div>
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
        <h3>{I18n.t('courses.course_details')}</h3>
        {elements}
      </div>
    );
  }
});


export default CourseDetails;
