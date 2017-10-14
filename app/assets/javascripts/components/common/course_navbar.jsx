import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router';
import GetHelpButton from './get_help_button.jsx';
import CourseUtils from '../../utils/course_utils.js';

const onCourseIndex = (location) => {
  return location.pathname.split('/').length === 4;
};

const CourseNavbar = ({ course, location, currentUser, courseLink }) => {
  // ///////////////
  // Course title //
  // ///////////////
  let courseLinkElement;
  if (course.url) {
    courseLinkElement = (
      <a href={course.url} target="_blank">
        <h2 className="title">{course.title}</h2>
      </a>
    );
  } else {
    courseLinkElement = <a><h2 className="title">{course.title}</h2></a>;
  }

  // ////////////
  // Home link //
  // ////////////

  let homeLinkClassName;
  if (onCourseIndex(location)) { homeLinkClassName = 'active'; }
  const homeLink = `${courseLink}/home`;

  // ///////////////
  // Timeline link /
  // ///////////////
  let timeline;
  if (course.timeline_enabled) {
    const timelineLink = `${courseLink}/timeline`;
    timeline = (
      <div className="nav__item" id="timeline-link">
        <p><Link to={timelineLink} activeClassName="active">{I18n.t('courses.timeline_link')}</Link></p>
      </div>
    );
  }

  // //////////////
  // Common tabs //
  // //////////////
  const studentsLink = `${courseLink}/students`;
  const articlesLink = `${courseLink}/articles`;
  const uploadsLink = `${courseLink}/uploads`;
  const activityLink = `${courseLink}/activity`;

  // ////////////
  // Chat link //
  // ////////////
  let chatNav;
  if (course.flags && course.flags.enable_chat) {
    const chatLink = `${courseLink}/chat`;
    chatNav = (
      <div className="nav__item" id="activity-link">
        <p><Link to={chatLink} activeClassName="active">{I18n.t('chat.label')}</Link></p>
      </div>
    );
  }

  // /////////////////
  // Get Help button /
  // /////////////////
  let getHelp;
  if (Features.enableGetHelpButton) {
    getHelp = (
      <div className="nav__button" id="get-help-button">
        <GetHelpButton course={course} currentUser={currentUser} key="get_help" />
      </div>
    );
  }

  return (
    <div className="container">
      {courseLinkElement}
      <nav>
        <div className="nav__item" id="overview-link">
          <p><Link to={homeLink} className={homeLinkClassName} activeClassName="active">{I18n.t('courses.overview')}</Link></p>
        </div>
        {timeline}
        <div className="nav__item" id="students-link">
          <p><Link to={studentsLink} activeClassName="active">{CourseUtils.i18n('students_short', course.string_prefix)}</Link></p>
        </div>
        <div className="nav__item" id="articles-link">
          <p><Link to={articlesLink} activeClassName="active">{I18n.t('articles.label')}</Link></p>
        </div>
        <div className="nav__item" id="uploads-link">
          <p><Link to={uploadsLink} activeClassName="active">{I18n.t('uploads.label')}</Link></p>
        </div>
        <div className="nav__item" id="activity-link">
          <p><Link to={activityLink} activeClassName="active">{I18n.t('activity.label')}</Link></p>
        </div>
        {chatNav}
        {getHelp}
      </nav>
    </div>
  );
};

CourseNavbar.propTypes = {
  course: PropTypes.object,
  location: PropTypes.object,
  currentUser: PropTypes.object,
  courseLink: PropTypes.string
};

export default CourseNavbar;
