import React from 'react';
import { Link } from 'react-router';
import CourseLink from './common/course_link.jsx';
import ServerActions from '../actions/server_actions.js';
import CourseActions from '../actions/course_actions.js';
import CourseStore from '../stores/course_store.js';
import UserStore from '../stores/user_store.js';
import NotificationStore from '../stores/notification_store.js';
import Affix from './common/affix.jsx';
import CourseUtils from '../utils/course_utils.js';
import GetHelpButton from '../components/common/get_help_button.jsx';
import EnrollCard from './enroll/enroll_card.jsx';

const getState = function () {
  const current = $('#react_root').data('current_user');
  const cu = UserStore.getFiltered({ id: current.id })[0];
  return {
    course: CourseStore.getCourse(),
    current_user: cu || current
  };
};

const Course = React.createClass({
  displayName: 'Course',

  propTypes: {
    params: React.PropTypes.object,
    location: React.PropTypes.object,
    children: React.PropTypes.node
  },

  mixins: [CourseStore.mixin, UserStore.mixin, NotificationStore.mixin],

  getInitialState() {
    return getState();
  },

  componentWillMount() {
    ServerActions.fetch('course', this.getCourseID());
    ServerActions.fetch('users', this.getCourseID());
    return ServerActions.fetch('campaigns', this.getCourseID());
  },

  getCourseID() {
    const { params } = this.props;
    return `${params.course_school}/${params.course_title}`;
  },
  getCurrentUser() {
    return this.state.current_user;
  },

  storeDidChange() {
    return this.setState(getState());
  },
  submit(e) {
    e.preventDefault();
    if (!confirm(I18n.t('courses.warn_mirrored'))) { return; }
    const toPass = $.extend(true, {}, this.state.course);
    toPass.submitted = true;
    return CourseActions.updateCourse(toPass, true);
  },
  _courseLinkParams() {
    return `/courses/${this.props.params.course_school}/${this.props.params.course_title}`;
  },
  _onCourseIndex() {
    return this.props.location.pathname.split('/').length === 4;
  },
  dismissSurvey(surveyNotificationId) {
    if (confirm(I18n.t('courses.dismiss_survey_confirm'))) {
      return CourseActions.dismissNotification(surveyNotificationId);
    }
  },
  render() {
    const alerts = [];

    let courseLink;
    if (this.state.course.url) {
      courseLink = (
        <a href={this.state.course.url} target="_blank">
          <h2 className="title">{this.state.course.title}</h2>
        </a>
      );
    } else {
      courseLink = <a><h2 className="title">{this.state.course.title}</h2></a>;
    }

    let userObject;
    if (this.getCurrentUser().id) {
      userObject = UserStore.getFiltered({ id: this.getCurrentUser().id })[0];
    }
    const userRole = userObject ? userObject.role : -1;

    // ///////////////
    // Timeline link /
    // ///////////////
    let timeline;
    if (this.state.course.type === 'ClassroomProgramCourse') {
      const timelineLink = `${this._courseLinkParams()}/timeline`;
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link to={timelineLink} activeClassName="active">{I18n.t('courses.timeline_link')}</Link></p>
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
          <GetHelpButton course={this.state.course} current_user={this.getCurrentUser()} key="get_help" />
        </div>
      );
    }

    // //////////////////////////////////
    // Admin / Instructor notifications /
    // //////////////////////////////////
    if ((userRole > 0 || this.getCurrentUser().admin) && !this.state.course.legacy && !this.state.course.published) {
      if (CourseStore.isLoaded() && !(this.state.course.submitted || this.state.published) && this.state.course.type === 'ClassroomProgramCourse') {
        alerts.push((
          <div className="notification" key="submit">
            <div className="container">
              <p>{I18n.t('courses.review_timeline')}</p>
              <a href="#" onClick={this.submit} className="button">{I18n.t('application.submit')}</a>
            </div>
          </div>
        )
        );
      }

      if (this.state.course.submitted) {
        if (!this.getCurrentUser().admin) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>{I18n.t('courses.submitted_note')}</p>
              </div>
            </div>
          )
          );
        } else {
          const overviewLink = `${this._courseLinkParams()}/overview`;
          alerts.push((
            <div className="notification" key="publish">
              <div className="container">
                <p>{I18n.t('courses.submitted_admin')}</p>
                <CourseLink to={overviewLink} className="button">{I18n.t('courses.overview')}</CourseLink>
              </div>
            </div>
          )
          );
        }
      }
    }

    if ((userRole > 0 || this.getCurrentUser().admin) && this.state.course.published && UserStore.isLoaded() && UserStore.getFiltered({ role: 0 }).length === 0 && !this.state.course.legacy) {
      const enrollEquals = '?enroll=';
      const url = window.location.origin + this._courseLinkParams() + enrollEquals + this.state.course.passcode;
      alerts.push((
        <div className="notification" key="enroll">
          <div className="container">
            <div>
              <p>{CourseUtils.i18n('published', this.state.course.string_prefix)}</p>
              <a href={url}>{url}</a>
            </div>
          </div>
        </div>
      )
      );
    }

    // ////////////////////////
    // Training notifications /
    // ////////////////////////
    if (this.state.course.incomplete_assigned_modules && this.state.course.incomplete_assigned_modules.length) {
      // `table` key is because it comes back as an openstruct
      const module = this.state.course.incomplete_assigned_modules[0].table;
      const messageKey = moment().isAfter(module.due_date, 'day') ? 'courses.training_overdue' : 'courses.training_due';

      alerts.push(
        <div className="notification" key="upcoming_module">
          <div className="container">
            <p>{I18n.t(messageKey, { title: module.title, date: module.due_date })}</p>
            <a href={module.link} className="button pull-right">{I18n.t('courses.training_nav')}</a>
          </div>
        </div>
      );
    }

    // //////////////////////
    // Survey notifications /
    // //////////////////////
    if (this.state.course.survey_notifications && this.state.course.survey_notifications.length) {
      this.state.course.survey_notifications.map(notification => {
        const dismissOnClick = () => this.dismissSurvey(notification.id);
        return alerts.push(
          <div className="notification notification--survey" key={"survey_notification_#{notification.id}"}>
            <div className="container">
              <p>{notification.message || CourseUtils.i18n('survey.notification_message', this.state.course.string_prefix)}</p>
              <a href={notification.survey_url} className="button pull-right">{CourseUtils.i18n('survey.link', this.state.course.string_prefix)}</a>
              <button className="button small pull-right border inverse-border" onClick={dismissOnClick}>{I18n.t('courses.dismiss_survey')}</button>
            </div>
          </div>
        );
      }
      );
    }

    // //////////////////
    // Enrollment modal /
    // //////////////////
    let enrollCard;
    if (this.props.location.query.enroll || this.props.location.query.enrolled) {
      enrollCard = (
        <EnrollCard
          user={this.getCurrentUser()}
          userRole={userRole}
          course={this.state.course}
          courseLink={this._courseLinkParams()}
          passcode={this.props.location.query.enroll}
          enrolledParam={this.props.location.query.enrolled}
          enrollFailureReason={this.props.location.query.failure_reason}
        />
      );
    }

    let overviewLinkClassName;
    if (this._onCourseIndex()) { overviewLinkClassName = 'active'; }
    const overviewLink = `${this._courseLinkParams()}/overview`;
    const studentsLink = `${this._courseLinkParams()}/students`;
    const articlesLink = `${this._courseLinkParams()}/articles`;
    const uploadsLink = `${this._courseLinkParams()}/uploads`;
    const activityLink = `${this._courseLinkParams()}/activity`;

    return (
      <div>
        <div className="course-nav__wrapper">
          <Affix className="course_navigation" offset={57 + NotificationStore.getNotifications().length * 52}>
            <div className="container">
              {courseLink}
              <nav>
                <div className="nav__item" id="overview-link">
                  <p><Link to={overviewLink} className={overviewLinkClassName} activeClassName="active">{I18n.t('courses.overview')}</Link></p>
                </div>
                {timeline}
                <div className="nav__item" id="students-link">
                  <p><Link to={studentsLink} activeClassName="active">{CourseUtils.i18n('students_short', this.state.course.string_prefix)}</Link></p>
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
                {getHelp}
              </nav>
            </div>
          </Affix>
        </div>
        <div className="course-alerts">
          {alerts}
        </div>
        <div className="course_main container">
          {enrollCard}
          {React.cloneElement(this.props.children, { course_id: this.getCourseID(), current_user: this.getCurrentUser(), course: this.state.course })}
        </div>
      </div>
    );
  }
});

export default Course;
