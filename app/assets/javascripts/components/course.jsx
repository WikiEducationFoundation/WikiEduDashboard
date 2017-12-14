import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseLink from './common/course_link.jsx';
import Confirm from './common/confirm.jsx';
import ServerActions from '../actions/server_actions.js';
import CourseActions from '../actions/course_actions.js';
import CourseStore from '../stores/course_store.js';
import UserStore from '../stores/user_store.js';
import WeekStore from '../stores/week_store.js';
import Affix from './common/affix.jsx';
import CourseUtils from '../utils/course_utils.js';
import UserUtils from '../utils/user_utils.js';
import EnrollCard from './enroll/enroll_card.jsx';
import CourseNavbar from './common/course_navbar.jsx';
import Notifications from './common/notifications.jsx';

const getState = function () {
  const current = $('#react_root').data('current_user');
  const cu = UserStore.getFiltered({ id: current.id })[0];
  let currentUser = cu || current;
  const userRoles = UserUtils.userRoles(currentUser, UserStore);
  currentUser = { ...currentUser, ...userRoles };
  return {
    course: CourseStore.getCourse(),
    current_user: currentUser,
    weeks: WeekStore.getWeeks()
  };
};

const Course = createReactClass({
  displayName: 'Course',

  propTypes: {
    params: PropTypes.object,
    location: PropTypes.object,
    children: PropTypes.node,
    current_user: PropTypes.object
  },

  mixins: [CourseStore.mixin, UserStore.mixin, WeekStore.mixin],

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

  dismissSurvey(surveyNotificationId) {
    if (confirm(I18n.t('courses.dismiss_survey_confirm'))) {
      return CourseActions.dismissNotification(surveyNotificationId);
    }
  },

  _courseLinkParams() {
    return `/courses/${this.props.params.course_school}/${this.props.params.course_title}`;
  },

  render() {
    const courseId = this.getCourseID();
    if (!courseId || !this.state.course || !this.state.course.home_wiki) { return <div />; }

    const alerts = [];
    const userRoles = this.state.current_user;
    // //////////////////////////////////
    // Admin / Instructor notifications /
    // //////////////////////////////////

    // For unpublished courses, when viewed by an instructor or admin
    if (userRoles.isNonstudent && !this.state.course.legacy && !this.state.course.published) {
      // If it's an unsubmitted ClassroomProgramCourse
      if (CourseStore.isLoaded() && !(this.state.course.submitted || this.state.published) && this.state.course.type === 'ClassroomProgramCourse') {
        // Show submit button if there is a timeline with trainings, or user is admin.
        if (CourseUtils.hasTrainings(this.state.weeks) || userRoles.isAdmin) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>{I18n.t('courses.review_timeline')}</p>
                <a href="#" onClick={this.submit} className="button">{I18n.t('application.submit')}</a>
              </div>
            </div>
          ));
        // Show 'add trainings' message if there is a timeline with no trainings
        } else if (this.state.weeks.length) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>Please add student trainings to your assignment timeline. Assigning training modules is an essential part of Wiki Ed&apos;s best practices.</p>
                <a href={`${this._courseLinkParams()}/timeline`} className="button">Go to Timeline</a>
              </div>
            </div>
          ));
        // Show 'create a timeline' message if there is no timeline.
        } else {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>Please create a timeline for your course. You can build one from scratch from the Timeline tab, or use the Assignment Wizard to create a custom timeline based on Wiki Ed&apos;s best practices.</p>
                <a href={`${this._courseLinkParams()}/timeline`} className="button">Launch the Wizard</a>
              </div>
            </div>
          ));
        }
      }

      // When the course has been submitted
      if (this.state.course.submitted) {
        // Show instructors the 'submitted' notice.
        if (!userRoles.isAdmin) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>{I18n.t('courses.submitted_note')}</p>
              </div>
            </div>
          ));
        // Instruct admins to approve the course by adding a campaign.
        } else {
          const homeLink = `${this._courseLinkParams()}/home`;
          alerts.push((
            <div className="notification" key="publish">
              <div className="container">
                <p>{I18n.t('courses.submitted_admin')}</p>
                <CourseLink to={homeLink} className="button">{I18n.t('courses.overview')}</CourseLink>
              </div>
            </div>
          ));
        }
      }
    }

    // For published courses with no students, highlight the enroll link
    if (userRoles.isNonstudent && this.state.course.published && UserStore.isLoaded() && UserStore.getFiltered({ role: 0 }).length === 0 && !this.state.course.legacy) {
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
    // Show the enroll card if either the `enroll` or `enrolled` param is present.
    // The enroll param may be blank if the course has no passcode.
    if (this.props.location.query.enroll !== undefined || this.props.location.query.enrolled) {
      enrollCard = (
        <EnrollCard
          user={this.state.current_user}
          userRoles={userRoles}
          course={this.state.course}
          courseLink={this._courseLinkParams()}
          passcode={this.props.location.query.enroll}
          enrolledParam={this.props.location.query.enrolled}
          enrollFailureReason={this.props.location.query.failure_reason}
        />
      );
    }

    return (
      <div>
        <div className="course-nav__wrapper">
          <Affix className="course_navigation" offset={57}>
            <CourseNavbar
              course={this.state.course}
              location={this.props.location}
              currentUser={this.state.current_user}
              courseLink={this._courseLinkParams()}
            />
            <Notifications />
          </Affix>
        </div>
        <div className="course-alerts">
          {alerts}
        </div>
        <div className="course_main container">
          <Confirm />
          {enrollCard}
          {React.cloneElement(this.props.children, { course_id: courseId, current_user: this.state.current_user, course: this.state.course })}
        </div>
      </div>
    );
  }
});

export default Course;
