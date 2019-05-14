import React from 'react';
import PropTypes from 'prop-types';
import { NavLink } from 'react-router-dom';
import GetHelpButton from './get_help_button.jsx';
import CourseUtils from '../../utils/course_utils.js';


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
  if (CourseUtils.onCourseIndex(location)) { homeLinkClassName = 'active'; }
  const homeLink = `${courseLink}/home`;

  // ///////////////
  // Timeline link /
  // ///////////////
  let timeline;
  if (course.timeline_enabled) {
    const timelineLink = `${courseLink}/timeline`;
    timeline = (
      <div className="nav__item" id="timeline-link">
        <p><NavLink to={timelineLink} activeClassName="active">{I18n.t('courses.timeline_link')}</NavLink></p>
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
  const resourcesLink = `${courseLink}/resources`;

  // ////////////
  // Chat link //
  // ////////////
  let chatNav;
  if (course.flags && course.flags.enable_chat) {
    const chatLink = `${courseLink}/chat`;
    chatNav = (
      <div className="nav__item" id="activity-link">
        <p><NavLink to={chatLink} activeClassName="active">{I18n.t('chat.label')}</NavLink></p>
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
          <p><NavLink to={homeLink} className={homeLinkClassName} activeClassName="active">{I18n.t('courses.overview')}</NavLink></p>
        </div>
        {timeline}
        <div className="nav__item" id="students-link">
          <p><NavLink to={studentsLink} activeClassName="active">{CourseUtils.i18n('students_short', course.string_prefix)}</NavLink></p>
        </div>
        <div className="nav__item" id="articles-link">
          <p><NavLink to={articlesLink} activeClassName="active">{I18n.t('articles.label')}</NavLink></p>
        </div>
        <div className="nav__item" id="uploads-link">
          <p><NavLink to={uploadsLink} activeClassName="active">{I18n.t('uploads.label')}</NavLink></p>
        </div>
        <div className="nav__item" id="activity-link">
          <p><NavLink to={activityLink} activeClassName="active">{I18n.t('activity.label')}</NavLink></p>
        </div>
        <div className="nav__item" id="resources-link">
          <p><NavLink to={resourcesLink} activeClassName="active">{I18n.t('resources.label')}</NavLink></p>
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
