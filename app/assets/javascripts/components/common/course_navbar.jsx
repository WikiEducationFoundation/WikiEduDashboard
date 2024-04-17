import React from 'react';
import PropTypes from 'prop-types';
import { NavLink } from 'react-router-dom';
import GetHelpButton from './get_help_button.jsx';
import CourseUtils from '../../utils/course_utils.js';


const CourseNavbar = ({ course, courseSlug, location, currentUser, courseLink }) => {
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
        <p><NavLink to={timelineLink} className={({ isActive }) => (isActive ? 'active' : '')}>{I18n.t('courses.timeline_link')}</NavLink></p>
      </div>
    );
  }

  let resources;
  if (course.timeline_enabled) {
    const resourcesLink = `${courseLink}/resources`;
    resources = (
      <div className="nav__item" id="resources-link">
        <p><NavLink to={resourcesLink} className={({ isActive }) => (isActive ? 'active' : '')}>{I18n.t('resources.label')}</NavLink></p>
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

  // /////////////////
  // Get Help button /
  // /////////////////
  let getHelp;
  if (Features.enableGetHelpButton) {
    getHelp = (
      <div className="nav__button" id="get-help-button">
        <GetHelpButton course={course} currentUser={currentUser} key="get_help" courseSlug={courseSlug} onTrainingPage={false}/>
      </div>
    );
  }

  return (
    <div className="container">
      {courseLinkElement}
      <nav>
        <div className="nav__item" id="overview-link">
          <p><NavLink to={homeLink} className={({ isActive }) => (isActive ? 'active' : homeLinkClassName)}>{I18n.t('courses.overview')}</NavLink></p>
        </div>
        {timeline}
        <div className="nav__item" id="students-link">
          <p><NavLink to={studentsLink} className={({ isActive }) => (isActive ? 'active' : '')}>{CourseUtils.i18n('students_short', course.string_prefix)}</NavLink></p>
        </div>
        <div className="nav__item" id="articles-link">
          <p><NavLink to={articlesLink} className={({ isActive }) => (isActive ? 'active' : '')}>{CourseUtils.i18n('articles_short', course.wiki_string_prefix)}</NavLink></p>
        </div>
        <div className="nav__item" id="uploads-link">
          <p><NavLink to={uploadsLink} className={({ isActive }) => (isActive ? 'active' : '')}>{I18n.t('uploads.label')}</NavLink></p>
        </div>
        <div className="nav__item" id="activity-link">
          <p><NavLink to={activityLink} className={({ isActive }) => (isActive ? 'active' : '')}>{I18n.t('activity.label')}</NavLink></p>
        </div>
        {resources}
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
