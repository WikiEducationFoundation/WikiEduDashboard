import React from 'react';
import PropTypes from 'prop-types';
import NewAccountButton from './new_account_button.jsx';

const EnrollCard = ({
  user, userRoles, course, courseLink, passcode, enrolledParam, enrollFailureReason
}) => {
  let messageBody;
  if (course.ended) {
    messageBody = (
      <div>
        <h1>{I18n.t('courses.ended')}</h1>
      </div>
    );
  } else if (course.flags.event_sync) {
    messageBody = (
      <div>
        <h1>{I18n.t('courses.controlled_by_event_center')}</h1>
      </div>
    );
  } else if (enrolledParam !== undefined) {
    // Enrollment is complete
    if (enrolledParam === 'true') {
      messageBody = (
        <div>
          <h1>{I18n.t('application.greeting2')}</h1>
          <p>{I18n.t('courses.join_successful', { title: course.title || '' })}</p>
        </div>
      );
    // Enrollment failed (not approved?)
    } else if (enrolledParam === 'false') {
      messageBody = (
        <div>
          <h1>{I18n.t('courses.join_failed')}</h1>
          <p>{I18n.t(`courses.join_failure_details.${enrollFailureReason}`)}</p>
        </div>
      );
    }
  // User is logged in and ready to enroll
  } else if (user.id && userRoles.notEnrolled) {
    messageBody = (
      <div>
        <h1>{I18n.t('courses.join_prompt', { title: course.title || '' })}</h1>
        <a className="button dark" href={course.enroll_url + passcode}>{I18n.t('courses.join')}</a>
        <a className="button border" href={courseLink}>{I18n.t('application.cancel')}</a>
      </div>
    );
  // User is already enrolled
  } else if (userRoles.isEnrolled) {
    messageBody = <h1>{I18n.t('courses.already_enrolled', { title: course.title })}</h1>;
  // User is not logged in
  } else if (!user.id) {
    // Login link relies on rails/ujs to turn the anchor link into
    // a POST request based on data-method="post". Otherwise, this
    // needs to become a button or form and include the authenticity token.
    messageBody = (
      <div>
        <h1>{I18n.t('application.greeting')}</h1>
        <p>{I18n.t('courses.invitation', { title: course.title })}</p>
        <p>{I18n.t('courses.invitation_username_advice')}</p>
        <div>
          <a data-method="post" href={`/users/auth/mediawiki?origin=${window.location}`} className="button auth dark">
            <i className="icon icon-wiki-logo" /> {I18n.t('application.log_in_extended')}
          </a>
          <NewAccountButton course={course} passcode={passcode} currentUser={user} />
        </div>
      </div>
    );
  }

  let closeLink;
  if (course.passcode !== '') {
    closeLink = (
      <a href={courseLink}>
        <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{ fill: 'currentcolor', verticalAlign: 'middle', width: '32px', height: '32px' }} >
          <g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z" /></g>
        </svg>
      </a>
    );
  }

  return (
    <div className="module enroll">
      {closeLink}
      {messageBody}
    </div>
  );
};

EnrollCard.propTypes = {
  user: PropTypes.object,
  userRoles: PropTypes.object,
  course: PropTypes.object,
  courseLink: PropTypes.string,
  passcode: PropTypes.string,
  enrolledParam: PropTypes.string,
  enrollFailureReason: PropTypes.string
};

export default EnrollCard;
