import React, { useState } from 'react';
import PropTypes from 'prop-types';
import AdviceModal from './advice_modal';

// The application card on a Scholars & Scientists course's apply link,
// /courses/<slug>/apply (Wiki Education Dashboard only). It follows the enroll
// card: while the form is open, a logged-out visitor is told an account is
// needed and offered log-in or sign-up, which both return here, and a logged-in
// visitor gets the course's intro and a link to the form. Otherwise it shows the
// submitted confirmation (to someone who applied) or the closed notice.
// `course.application` comes from the course JSON.
const ApplyCard = ({ user, course }) => {
  const [modalShown, setModalShown] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  const application = course.application;

  let messageBody;
  if (!application.applied && !application.open) {
    messageBody = <p>{I18n.t('course_applications.closed')}</p>;
  } else if (!user.id) {
    // The login link relies on rails/ujs turning data-method="post" into a POST.
    messageBody = (
      <div>
        <h1>{I18n.t('course_applications.accepting')}</h1>
        <p>{I18n.t('course_applications.account_needed')}</p>
        <p>{I18n.t('courses.invitation_username_advice')}</p>
        <div>
          <a data-method="post" href={`/users/auth/mediawiki?origin=${window.location}`} className="button auth dark">
            <i className="icon icon-wiki-white" /> {I18n.t('application.log_in_extended')}
          </a>
          <button
            type="button"
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            onClick={() => setModalShown(true)}
            className="button auth signup border margin"
          >
            <i className={`icon ${isHovered ? 'icon-wiki-white' : ' icon-wiki-purple'}`} /> {I18n.t('application.sign_up_extended')}
          </button>
        </div>
      </div>
    );
  } else if (application.applied) {
    messageBody = <p>{I18n.t('course_applications.submitted')}</p>;
  } else {
    messageBody = (
      <div>
        <h1>{I18n.t('course_applications.accepting')}</h1>
        {/* Staff-written; the server sanitizes and formats it with simple_format. */}
        {application.intro_html && <div className="apply-card__intro" dangerouslySetInnerHTML={{ __html: application.intro_html }} />}
        <a className="button dark" href={application.form_url}>{I18n.t('course_applications.apply')}</a>
      </div>
    );
  }

  // Sign-up through account requests would try to enroll the new account,
  // which an application course refuses, so the advice modal always offers
  // the plain Wikipedia sign-up.
  const signupCourse = { ...course, account_requests_enabled: false };

  return (
    <div className="module enroll apply-card">
      {messageBody}
      {modalShown && <AdviceModal setModalShown={setModalShown} course={signupCourse} user={user} />}
    </div>
  );
};

ApplyCard.propTypes = {
  user: PropTypes.object,
  course: PropTypes.object
};

export default ApplyCard;
