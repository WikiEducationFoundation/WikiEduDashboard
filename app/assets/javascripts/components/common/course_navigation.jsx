import React from 'react';
import { Link } from 'react-router';
import Affix from './affix.jsx';
import CourseUtils from '../../utils/course_utils.js';
import GetHelpButton from './get_help_button.jsx';
import NotificationStore from '../../stores/notification_store.js';

const CourseNavigation = React.createClass({
  displayName: 'CourseNavigation',

  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object,
    location: React.PropTypes.object,
    baseUrl: React.PropTypes.string
  },

  mixins: [NotificationStore.mixin],

  _onCourseIndex() {
    return this.props.location.pathname.split('/').length === 4;
  },

  render() {
    // //////////////////////
    // Course name and link /
    // //////////////////////
    let courseLink;
    if (this.props.course.url) {
      courseLink = (
        <a href={this.props.course.url} target="_blank">
          <h2 className="title">{this.props.course.title}</h2>
        </a>
      );
    } else {
      courseLink = <a><h2 className="title">{this.props.course.title}</h2></a>;
    }

    // ////////////////////
    // Home / course root /
    // ////////////////////
    let homeLinkClassName;
    // Special handling for styling when the url is the course root instead of /home
    if (this._onCourseIndex()) { homeLinkClassName = 'active'; }
    const homeLink = `${this.props.baseUrl}/home`;

    // ///////////////
    // Timeline link /
    // ///////////////
    let timeline;
    if (this.props.course.type === 'ClassroomProgramCourse') {
      const timelineLink = `${this.props.baseUrl}/timeline`;
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link to={timelineLink} activeClassName="active">{I18n.t('courses.timeline_link')}</Link></p>
        </div>
      );
    }

    // ///////////////
    // Standard tabs /
    // ///////////////
    const studentsLink = `${this.props.baseUrl}/students`;
    const articlesLink = `${this.props.baseUrl}/articles`;
    const uploadsLink = `${this.props.baseUrl}/uploads`;
    const activityLink = `${this.props.baseUrl}/activity`;

    // ///////////
    // Chat link /
    // ///////////
    let chatNav;
    if (this.props.course && this.props.course.flags && this.props.course.flags.enable_chat) {
      const chatLink = `${this.props.baseUrl}/chat`;
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
          <GetHelpButton course={this.props.course} current_user={this.props.current_user} key="get_help" />
        </div>
      );
    }

    return (
      <div className="course-nav__wrapper">
        <Affix className="course_navigation" offset={57 + NotificationStore.getNotifications().length * 52}>
          <div className="container">
            {courseLink}
            <nav>
              <div className="nav__item" id="overview-link">
                <p><Link to={homeLink} className={homeLinkClassName} activeClassName="active">{I18n.t('courses.overview')}</Link></p>
              </div>
              {timeline}
              <div className="nav__item" id="students-link">
                <p><Link to={studentsLink} activeClassName="active">{CourseUtils.i18n('students_short', this.props.course.string_prefix)}</Link></p>
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
        </Affix>
      </div>
    );
  }
});

export default CourseNavigation;
