import React from 'react';
import { Link } from 'react-router';
import GetHelpButton from './get_help_button.jsx';
import CourseUtils from '../../utils/course_utils.js';

const CourseNavbar = React.createClass({
  displayName: 'CourseNavbar',

  propTypes: {
    course: React.PropTypes.object,
    params: React.PropTypes.object,
    location: React.PropTypes.object,
    current_user: React.PropTypes.object,
    courseLink: React.PropTypes.string
  },

  _onCourseIndex() {
    return this.props.location.pathname.split('/').length === 4;
  },

  render() {
    // ///////////////
    // Course title //
    // ///////////////
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

    // ////////////
    // Home link //
    // ////////////

    let homeLinkClassName;
    if (this._onCourseIndex()) { homeLinkClassName = 'active'; }
    const homeLink = `${this.props.courseLink}/home`;

    // ///////////////
    // Timeline link /
    // ///////////////
    let timeline;
    if (this.props.course.type === 'ClassroomProgramCourse') {
      const timelineLink = `${this.props.courseLink}/timeline`;
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link to={timelineLink} activeClassName="active">{I18n.t('courses.timeline_link')}</Link></p>
        </div>
      );
    }

    // //////////////
    // Common tabs //
    // //////////////
    const studentsLink = `${this.props.courseLink}/students`;
    const articlesLink = `${this.props.courseLink}/articles`;
    const uploadsLink = `${this.props.courseLink}/uploads`;
    const activityLink = `${this.props.courseLink}/activity`;

    // ////////////
    // Chat link //
    // ////////////
    let chatNav;
    if (this.props.course && this.props.course.flags && this.props.course.flags.enable_chat) {
      const chatLink = `${this.props.courseLink}/chat`;
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
    );
  }
});

export default CourseNavbar;
