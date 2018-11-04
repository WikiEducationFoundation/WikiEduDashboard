import moment from 'moment';
import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';

import CourseUtils from '../utils/course_utils';
import CourseAlert from './course_alert';
import OptInNotification from './common/opt_in_notification';

const CourseAlerts = createReactClass({
  displayName: 'CourseAlerts',

  propTypes: {
    userRoles: PropTypes.object.isRequired,
    course: PropTypes.object.isRequired,
    weeks: PropTypes.any.isRequired,
    courseLinkParams: PropTypes.string.isRequired,
    usersLoaded: PropTypes.bool.isRequired,
    studentCount: PropTypes.number.isRequired,
    updateCourse: PropTypes.func.isRequired,
    persistCourse: PropTypes.func.isRequired,
    dismissNotification: PropTypes.func.isRequired
  },

  submit(e) {
    e.preventDefault();
    if (!confirm(I18n.t('courses.warn_mirrored'))) { return; }
    this.props.updateCourse({ submitted: true });
    return this.props.persistCourse(this.props.course.slug);
  },

  dismissSurvey(surveyNotificationId) {
    if (confirm(I18n.t('courses.dismiss_survey_confirm'))) {
      return this.props.dismissNotification(surveyNotificationId);
    }
  },

  render() {
    const course = this.props.course;
    const userRoles = this.props.userRoles;

    const alerts = [];

    // //////////////////////////////////
    // Admin / Instructor notifications /
    // //////////////////////////////////
    // For unpublished courses, when viewed by an instructor or admin
    if (userRoles.isNonstudent && !course.legacy && !course.published) {
      // If it's an unsubmitted ClassroomProgramCourse
      const isUnsubmittedClassroomProgramCourse = !course.submitted && course.type === 'ClassroomProgramCourse';
      if (isUnsubmittedClassroomProgramCourse) {
        // Show submit button if there is a timeline with trainings, or user is admin.
        if (CourseUtils.hasTrainings(this.props.weeks) || userRoles.isAdmin) {
          alerts.push(<CourseAlert key="submit" message={I18n.t('courses.review_timeline')} actionMessage={I18n.t('application.submit')} buttonLink="#" onClick={this.submit} />);
          // Show 'add trainings' message if there is a timeline with no trainings
        } else if (this.props.weeks.length) {
          alerts.push(<CourseAlert key="submit" message={I18n.t('courses.add_trainings')} actionMessage={I18n.t('courses.timeline_nav')} buttonLink={`${this.props.courseLinkParams}/timeline`} />);
          // Show 'create a timeline' message if there is no timeline.
        } else {
          alerts.push(<CourseAlert key="submit" message={I18n.t('courses.review_timeline')} actionMessage={I18n.t('courses.launch_wizard')} buttonLink={`${this.props.courseLinkParams}/timeline/wizard`} />);
        }
      }
      if (!(course.type === 'ClassroomProgramCourse')) {
        alerts.push(<CourseAlert key="noCampaign" message={I18n.t('courses.no_campaign')} />);
      }
      // When the course has been submitted
      if (course.submitted) {
        // Show instructors the 'submitted' notice.
        if (!userRoles.isAdmin) {
          alerts.push(<CourseAlert key="submit" message={I18n.t('courses.submitted_note')} />);
          // Instruct admins to approve the course by adding a campaign.
        } else {
          const homeLink = `${this.props.courseLinkParams}/home`;
          alerts.push(<CourseAlert key="publish" message={I18n.t('courses.submitted_admin')} courseLink={homeLink} actionMessage={I18n.t('courses.overview')} />);
        }
      }
    }

    // For published courses with no students, highlight the enroll link
    const hasNoStudents = this.props.usersLoaded && this.props.studentCount === 0;
    if (userRoles.isNonstudent && course.published && hasNoStudents && !course.legacy) {
      const enrollEquals = '?enroll=';
      const url = window.location.origin + this.props.courseLinkParams + enrollEquals + course.passcode;
      alerts.push((
        <div className="notification" key="enroll">
          <div className="container">
            <div>
              <p>{CourseUtils.i18n('published', course.string_prefix)}</p>
              <a href={url}>{url}</a>
            </div>
          </div>
        </div>
      ));
    }

    // ////////////////////////
    // Training notifications /
    // ////////////////////////
    if (course.incomplete_assigned_modules && course.incomplete_assigned_modules.length) {
      // `table` key is because it comes back as an openstruct
      const module = course.incomplete_assigned_modules[0].table;
      const messageKey = moment().isAfter(module.due_date, 'day') ? 'courses.training_overdue' : 'courses.training_due';

      alerts.push(<CourseAlert key="upcoming_module" message={I18n.t(messageKey, { title: module.title, date: module.due_date })} buttonLink={module.link} actionClassName="pull-right" actionMessage={I18n.t('courses.training_nav')} />);
    }

    // //////////////////////
    // Survey notifications /
    // //////////////////////
    if (course.survey_notifications && course.survey_notifications.length) {
      course.survey_notifications.forEach((notification) => {
        const dismissOnClick = () => this.dismissSurvey(notification.id);
        return alerts.push(<CourseAlert key={`survey_notification_${notification.id}`} message={notification.message || I18n.t('courses.survey.notification_message')} className="notification--survey" actionLink={notification.survey_url} actionClassName="pull-right" actionMessage={I18n.t('courses.survey.link')} components={<button className="button small pull-right border inverse-border" onClick={dismissOnClick}>{I18n.t('courses.dismiss_survey')}</button>} />);
      });
    }

    // //////////////////////////
    // Experiment notifications /
    // //////////////////////////
    if (course.experiment_notification) {
      alerts.push(<OptInNotification notification={course.experiment_notification} key="opt_in" />);
    }
    return (
      <div className="course-alerts">
        {alerts}
      </div>
    );
  }
});

export default CourseAlerts;
