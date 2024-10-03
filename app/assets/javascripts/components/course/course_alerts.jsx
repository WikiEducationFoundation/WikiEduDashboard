import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils';
import CourseAlert from './course_alert';
import OptInNotification from '../common/opt_in_notification';
import { isAfter, startOfDay } from 'date-fns';
import { toDate } from '../../utils/date_utils';

const CourseAlerts = ({
  userRoles,
  course,
  courseAlerts,
  weeks,
  courseLinkParams,
  usersLoaded,
  studentCount,
  updateCourse,
  persistCourse,
  dismissNotification
}) => {
  const [alerts, setAlerts] = useState([]);

  useEffect(() => {
    const updateAlerts = () => {
      const newAlerts = [];

      // //////////////////////////////////
      // Admin / Instructor notifications /
      // //////////////////////////////////
      // For unpublished courses, when viewed by an instructor or admin
      if (userRoles.isAdvancedRole && !course.legacy && !course.published) {
        // If it's an unsubmitted ClassroomProgramCourse
        const isUnsubmittedClassroomProgramCourse = !course.submitted && course.type === 'ClassroomProgramCourse';
        if (isUnsubmittedClassroomProgramCourse) {
          // Show submit button if there is a timeline with trainings, or user is admin.
          if (CourseUtils.hasTrainings(weeks) || userRoles.isAdmin) {
            // eslint-disable-next-line no-use-before-define
            newAlerts.push(<CourseAlert key="submit" message={I18n.t('courses.review_timeline')} actionMessage={I18n.t('application.submit')} buttonLink="#" onClick={submit} />);
            // Show 'add trainings' message if there is a timeline with no trainings
          } else if (weeks.length) {
            newAlerts.push(<CourseAlert key="submit" message={I18n.t('courses.add_trainings')} actionMessage={I18n.t('courses.timeline_nav')} buttonLink={`${courseLinkParams}/timeline`} />);
            // Show 'create a timeline' message if there is no timeline.
          } else {
            newAlerts.push(<CourseAlert key="submit" message={I18n.t('courses.review_timeline')} actionMessage={I18n.t('courses.launch_wizard')} buttonLink={`${courseLinkParams}/timeline/wizard`} />);
          }
        }
        if (!(course.type === 'ClassroomProgramCourse')) {
          newAlerts.push(<CourseAlert key="noCampaign" message={I18n.t('courses.no_campaign')} />);
        }
        // Show supplementary information if the user is an admin
        const { onboardingAlert } = courseAlerts;
        if (userRoles.isAdmin && onboardingAlert) {
          const message = CourseUtils.formatOnboardingAlertMessage(onboardingAlert.message);
          const url = `/alerts_list/${onboardingAlert.id}`;
          newAlerts.push(<CourseAlert key="supplementary" message={message} buttonLink={url} actionMessage={'Go to Alert'} />);
        }
        // When the course has been submitted
        if (course.submitted) {
          // Show instructors the 'submitted' notice.
          if (!userRoles.isAdmin) {
            newAlerts.push(<CourseAlert key="submit" message={I18n.t('courses.submitted_note')} buttonLink="/training" actionMessage={'View Training Modules'}/>);
            // Instruct admins to approve the course by adding a campaign.
          } else {
            const homeLink = `${courseLinkParams}/home`;
            newAlerts.push(<CourseAlert key="publish" message={I18n.t('courses.submitted_admin')} courseLink={homeLink} actionMessage={I18n.t('courses.overview')} />);
          }
        }
      }
      // Shows an alert for how many accounts have been requested
      if (course.requestedAccounts) {
        if ((!Features.wikiEd && userRoles.isAdvancedRole) || userRoles.isAdmin) {
          const message = I18n.t('courses.requested_accounts_alert', { count: course.requestedAccounts });
          const actionMessage = I18n.t('courses.requested_accounts_alert_view');
          const url = `/requested_accounts/${course.slug}`;
          newAlerts.push(<CourseAlert key="requested_accounts" message={message} href={url} actionMessage={actionMessage} />);
        }
      }
      // For published courses with no students, highlight the enroll link
      const hasNoStudents = usersLoaded && studentCount === 0;
      if (userRoles.isAdvancedRole && course.published && hasNoStudents && !course.legacy) {
        const enrollEquals = '?enroll=';
        const url = window.location.origin + courseLinkParams + enrollEquals + course.passcode;
        newAlerts.push((
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
        const messageKey = isAfter(
          startOfDay(new Date()),
          startOfDay(toDate(module.due_date))
        ) ? 'courses.training_overdue' : 'courses.training_due';

        newAlerts.push(<CourseAlert key="upcoming_module" message={I18n.t(messageKey, { title: module.title, date: module.due_date })} buttonLink={module.link} actionClassName="pull-right" actionMessage={I18n.t('courses.training_nav')} />);
      }

      // //////////////////////
      // Survey notifications /
      // //////////////////////
      if (course.survey_notifications && course.survey_notifications.length) {
        course.survey_notifications.forEach((notification) => {
          // eslint-disable-next-line no-use-before-define
          const dismissOnClick = () => dismissSurvey(notification.id);
          const components = (
            <button
              className="button small pull-right border inverse-border"
              onClick={dismissOnClick}
            >
              {I18n.t('courses.dismiss_survey')}
            </button>
          );

          newAlerts.push(
            <CourseAlert
              key={`survey_notification_${notification.id}`}
              actionClassName="pull-right"
              actionMessage={I18n.t('courses.survey.link')}
              className="notification--survey"
              components={components}
              href={notification.survey_url}
              message={notification.message || I18n.t('courses.survey.notification_message')}
            />
          );
        });
      }
      // ////////////////////////////////
      // Very Long Update notifications /
      // ////////////////////////////////
      if (course.flags && course.flags.very_long_update) {
        newAlerts.push(
          <CourseAlert
            key="updates_paused"
            message="Updates for this program or event have been taking too long and are currently paused. If you need updated data soon, please use the 'Report a problem' link to let us know."
            actionMessage="See details"
            buttonLink="https://phabricator.wikimedia.org/T277651"
          />
        );
      }

      // //////////////////////////
      // Experiment notifications /
      // //////////////////////////
      if (course.experiment_notification) {
        newAlerts.push(<OptInNotification notification={course.experiment_notification} key="opt_in" />);
      }
      setAlerts(newAlerts);
    };

    updateAlerts();
  }, [userRoles, course, courseAlerts, weeks, courseLinkParams, usersLoaded, studentCount]);

  const submit = (e) => {
    e.preventDefault();
    if (!confirm(I18n.t('courses.warn_mirrored'))) { return; }
    updateCourse({ submitted: true });
    return persistCourse(course.slug);
  };

  const dismissSurvey = (surveyNotificationId) => {
    if (confirm(I18n.t('courses.dismiss_survey_confirm'))) {
      return dismissNotification(surveyNotificationId);
    }
  };

  return (
    <div className="course-alerts">
      {alerts}
    </div>
  );
};

CourseAlerts.propTypes = {
  userRoles: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
  courseAlerts: PropTypes.object.isRequired,
  weeks: PropTypes.any.isRequired,
  courseLinkParams: PropTypes.string.isRequired,
  usersLoaded: PropTypes.bool.isRequired,
  studentCount: PropTypes.number.isRequired,
  updateCourse: PropTypes.func.isRequired,
  persistCourse: PropTypes.func.isRequired,
  dismissNotification: PropTypes.func.isRequired
};

export default CourseAlerts;
