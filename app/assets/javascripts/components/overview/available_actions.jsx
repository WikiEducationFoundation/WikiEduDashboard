import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { addNotification } from '../../actions/notification_actions.js';
import SalesforceLink from './salesforce_link.jsx';
import CourseStatsDownloadModal from './course_stats_download_modal.jsx';
import EmbedStatsButton from './embed_stats_button.jsx';
import CloneCourseButton from './clone_course_button.jsx';
import { enableAccountRequests } from '../../actions/new_account_actions.js';
import { needsUpdate, linkToSalesforce, updateSalesforceRecord, deleteCourse, removeAndDeleteCourse } from '../../actions/course_actions';
import { STUDENT_ROLE, ONLINE_VOLUNTEER_ROLE } from '../../constants/user_roles';
import { removeUser } from '../../actions/user_actions';
import NotifyInstructorsButton from './notify_instructors_button.jsx';


const AvailableActions = ({ course, current_user, updateCourse, courseCreationNotice }) => {
  const dispatch = useDispatch();

  const join = (role = null) => {
    const enrollURL = course.enroll_url;
    if (course.passcode === '' || role === 'online_volunteer') {
      const onConfirm = () => window.location = `${enrollURL}?role=${role}`;
      const confirmMessage = CourseUtils.i18n('join_no_passcode');
      dispatch(initiateConfirm({ confirmMessage, onConfirm }));
    } else {
      const onConfirm = (passcode) => {
        return window.location = `${enrollURL}${passcode}?role=${role}`;
      };
      const confirmMessage = I18n.t('courses.passcode_prompt');
      const explanation = CourseUtils.i18n('join_details', course.string_prefix);
      dispatch(initiateConfirm({ confirmMessage, onConfirm, showInput: true, explanation }));
    }
  };

  // NOTE: This is disabled until we have a better way to prevent manual updates from overloading the system.
  // const updateStats = () => {
  //   const updateUrl = `${window.location.origin}/courses/${course.slug}/manual_update`;
  //   const onConfirm = () => window.location = updateUrl;
  //   const confirmMessage = I18n.t('courses.confirm_manual_update');
  //   dispatch(initiateConfirm({ confirmMessage, onConfirm }));
  // };

  const leave = () => {
    const courseSlug = course.slug;
    const role = current_user.isOnlineVolunteer ? ONLINE_VOLUNTEER_ROLE : STUDENT_ROLE;
    const userRecord = { user: { user_id: current_user.id, role } };
    const onConfirm = () => dispatch(removeUser(courseSlug, userRecord));
    const confirmMessage = I18n.t('courses.leave_confirmation');
    dispatch(initiateConfirm({ confirmMessage, onConfirm }));
  };

  const deleteCourseFunc = () => {
    const courseSlug = course.slug;
    const enteredTitle = prompt(I18n.t('courses.confirm_course_deletion', { title: course.title }));
    // Check if enteredTitle is not null before calling trim.
    if (enteredTitle !== null && enteredTitle.trim() === course.title.trim()) {
      // If course has no campaigns, delete the course directly; otherwise, remove from campaign first.
      if (!course.campaigns || course.campaigns.length === 0) {
        return dispatch(deleteCourse(courseSlug));
      }
      const campaign = course.campaigns[0];
      const campaignTitle = campaign.title;
      const campaignId = campaign.id;
      const campaignSlug = campaign.slug;
      return dispatch(removeAndDeleteCourse(courseSlug, campaignTitle, campaignId, campaignSlug));
    } else if (enteredTitle) {
      return alert(I18n.t('courses.confirm_course_deletion_failed', { title: enteredTitle }));
    }
  };

  const needsUpdateFunc = () => {
    dispatch(needsUpdate(course.slug));
  };

  const enableRequests = () => {
    const onConfirm = () => {
      dispatch(enableAccountRequests(course));
      updateCourse(course);
      dispatch(addNotification({
        message: I18n.t('courses.accounts_generation_enabled'),
        closable: true,
        type: 'success'
      }));
    };
    const confirmMessage = I18n.t('courses.accounts_generation_confirm_message');
    const explanation = I18n.t('courses.accounts_generation_explanation');
    dispatch(initiateConfirm({ confirmMessage, onConfirm, showInput: false, explanation }));
  };

  const controls = [];
  const urlParams = new URLSearchParams(window.location.search);
  const isEnrollmentURL = urlParams.has('enroll');
  const user = current_user;

  // If user has a role in the course or is an admin
  if ((user.isEnrolled) || user.admin || user.isAdvancedRole) {
    // If user is a student, show the 'leave' button.
    if (user.isStudent || user.isOnlineVolunteer) {
      // 'Leave' is not available if the course is controlled by Event Center.
      if (!course.flags.event_sync) {
        controls.push((
          <div key="leave" className="available-action"><button onClick={leave} className="button">{CourseUtils.i18n('leave_course', course.string_prefix)}</button></div>
        ));
      }
    }
    // If user is admin, go to list of tickets related to this course
    if (user.admin) {
      controls.push((<div key="search" className="available-action"><a href={`/tickets/dashboard?search_by_course=${course.slug}`} className="button">{I18n.t('courses.search_all_tickets_for_this_course')}</a></div>));
    }
    // If course is not published, show the 'delete' button to instructors and admins.
    if ((user.isAdvancedRole || user.admin) && (!course.published || !Features.wikiEd)) {
      controls.push((
        <div title={Features.wikiEd ? I18n.t('courses.delete_course_instructions') : undefined} key="delete" className="available-action">
          <button className="button danger" onClick={deleteCourseFunc}>
            {CourseUtils.i18n('delete_course', course.string_prefix)}
          </button>
        </div>
      ));
    }
    // If the course is ended, show the 'needs update' button.
    if (CourseDateUtils.isEnded(course)) {
      controls.push((
        <div key="needs_update" className="available-action"><button className="button" onClick={needsUpdateFunc}>{I18n.t('courses.needs_update')}</button></div>
      ));
    }
  // If user has no role and is logged in, and if he is not on enrollment page, show 'Join course' button.
  // On enrollment page, 'Join course' button is not shown in Actions component to avoid confusion.
  // The 'Join course' button is not shown for courses controlled by Wikimedia Event Center.
  // The 'Join course' button is not shown on Wiki Education Dashboard.
  } else if (!course.ended && !isEnrollmentURL && !course.flags.event_sync && user.id && !Features.wikiEd) {
    controls.push(
      <div key="join" className="available-action"><button onClick={() => join()} className="button">{CourseUtils.i18n('join_course', course.string_prefix)}</button></div>
    );
    // On P&E Dashboard, offer option to join as online volunteer
    if (!Features.wikiEd && course.online_volunteers_enabled) {
      controls.push(
        <div key="volunteer" className="available-action"><button onClick={() => join('online_volunteer')} className="button">{CourseUtils.i18n('join_course_as_volunteer', course.string_prefix)}</button></div>
      );
    }
  }
  // If the user is enrolled in the course or admin, and the course type is editathon and not finished, show a manual stats update button
  // NOTE: This is disabled until we have a better way to prevent manual updates from overloading the system.
  // if ((user.isEnrolled || user.isAdmin) && (course.type === 'Editathon' && !course.ended)) {
  //   controls.push((
  //     <div key="updateStats" className="available-action"><button className="button" onClick={updateStats}>{I18n.t('courses.update_stats')}</button></div>
  //   ));
  // }

  // Requested accounts
  // These are enabled for instructors on P&E Dashboard, but only for admins on Wiki Education Dashboard.
  if ((user.isAdvancedRole && !Features.wikiEd) || user.admin) {
    // Enable account requests if allowed
    if (!course.account_requests_enabled) {
      controls.push((
        <div key="enable_account_requests" className="available-action"><button onClick={enableRequests} className="button">{I18n.t('courses.enable_account_requests')}</button></div>
      ));
    }
  }

  // If the user is an instructor or admin, and the course is published, show a stats download button
  // Always show the stats download for published non-Wiki Ed courses.
  if ((user.isAdvancedRole || user.admin || !Features.wikiEd) && course.published) {
    controls.push((
      <div key="download_course_stats" className="available-action"><CourseStatsDownloadModal course={course} /></div>
    ));
    controls.push((
      <div key="embed_course_stats" className="available-action"><EmbedStatsButton title={course.title} /></div>
    ));
  }

  if (user.admin) {
    controls.push((
      <div key="clone_course" className="available-action"><CloneCourseButton courseId={course.id} courseCreationNotice={courseCreationNotice}/></div>
    ));
  }

  if (user.admin && Features.wikiEd) {
    controls.push((
      <div key="notify_instructors" className="available-action"><NotifyInstructorsButton courseId={course.id} courseTitle={course.title} /></div>
    ));
  }

  // If no controls are available
  if (controls.length === 0) {
    controls.push(
      <div key="none" className="available-action">{I18n.t('courses.no_available_actions')}</div>
    );
  }

  return (
    <div className="module actions">
      <div className="section-header">
        <h3>{I18n.t('courses.actions')}</h3>
      </div>
      <div className="module__data">
        {controls}
        <SalesforceLink course={course} current_user={current_user} linkToSalesforce={linkToSalesforce} updateSalesforceRecord={updateSalesforceRecord} />
      </div>
    </div>
  );
};

AvailableActions.propTypes = {
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  courseCreationNotice: PropTypes.string
};

export default AvailableActions;
