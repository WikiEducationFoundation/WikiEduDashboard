import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import * as AlertActions from '../../actions/alert_actions.js';
import { getStaffUsers, getProgramManagers, getContentExperts } from '../../selectors';

import Expandable from '../high_order/expandable.jsx';

const GetHelpButton = (props) => {
  const [selectedTargetUser, setSelectedTargetUser] = useState(null);
  const [message, setMessage] = useState('');

  const reset = (e) => {
    e.preventDefault();
    setMessage('');
    setSelectedTargetUser(null);
    props.open(e);
    setTimeout(() => {
      props.actions.resetNeedHelpAlert();
    }, 500);
  };

  const updateTargetUser = (targetUser, e) => {
    e.preventDefault();
    setSelectedTargetUser(targetUser);
  };

  const clearHelper = (e) => {
    e.preventDefault();
    setSelectedTargetUser(null);
  };

  const updateMessage = (e) => {
    setMessage(e.target.value);
  };

  const submitNeedHelpMessage = (e) => {
    e.preventDefault();
    const messageData = {
      target_user_id: selectedTargetUser.id,
      message: message,
      course_id: props.course.id
    };
    props.actions.submitNeedHelpAlert(messageData);
  };

  const wikipediaHelpUser = () => {
    if (props.contentExperts && props.contentExperts.length > 0) {
      return props.contentExperts[0];
    } else if (props.programManagers && props.programManagers.length > 0) {
      return props.programManagers[0];
    }
    return props.staffUsers[0];
  };

  const programHelpUser = () => {
    if (props.programManagers && props.programManagers.length > 0) {
      return props.programManagers[0];
    } else if (props.contentExperts && props.contentExperts.length > 0) {
      return props.contentExperts[0];
    }
    return props.staffUsers[0];
  };

  const dashboardHelpUser = () => {
    return { username: 'Technical help staff' };
  };

  let content;
  let faqLink;

  let wikipediaHelpButton;
  let programHelpButton;
  let dashboardHelpButton;

  // Only show these contact buttons if there are staff assigned to the course.
  if (props.staffUsers && props.staffUsers.length > 0) {
    // Show the Wikipedia help button to everyone.
    const wikipediaUser = wikipediaHelpUser();
    wikipediaHelpButton = (
      <span className="contact-wikipedia-help" key={`${wikipediaUser.username}-wikipedia-help`}>
        <a href="#" className="wikipedia-help-link button dark small stacked" onClick={e => updateTargetUser(wikipediaUser, e)}>question about editing Wikipedia</a>
        <br />
      </span>
    );

    // Show the program help button only to instructors and other non-students.
    if (props.currentUser.isAdvancedRole) {
      const programUser = programHelpUser();
      programHelpButton = (
        <span className="contact-program-help" key={`${programUser.username}-program-help`}>
          <a href="#" className="program-help-link button dark stacked small" onClick={e => updateTargetUser(programUser, e)}>question about Wiki Ed or your assignment</a>
          <br />
        </span>
      );
    }

    // Show the dashboard help button to everyone.
    const dashboardUser = dashboardHelpUser();
    dashboardHelpButton = (
      <span className="contact-dashboard-help" key={`${dashboardUser.username}-dashboard-help`}>
        <a href="#" className="dashboard-help-link button dark stacked small" onClick={e => updateTargetUser(dashboardUser, e)}>question about the dashboard</a>
        <br />
      </span>
    );
  }

  let contactStaff;
  if (wikipediaHelpButton || programHelpButton || dashboardHelpButton) {
    contactStaff = (
      <div>
        <hr />
        <p className="target-users">
          Still need help? Get in touch with Wiki Education staff if you have a:
          <br />
          {wikipediaHelpButton}
          {programHelpButton}
          {dashboardHelpButton}
        </p>
      </div>
    );
  }

  if (props.alertSubmitting) {
    content = (
      <div className="text-center get-help-submitting">
        <strong>Sending message...</strong>
      </div>
    );
  } else if (props.alertCreated) {
    content = (
      <div className="get-help-submitted">
        <p className="text-center"><strong>Message sent!</strong></p>
        <p>
          We&apos;ll get back to you within 1 business day. Be sure to check your email for a response.
        </p>
        <a href="#" className="button" onClick={reset}>Ok</a>
      </div>
    );
  } else if (selectedTargetUser) {
    content = (
      <div className="get-help-form">
        <p><strong>To: {selectedTargetUser.username}</strong></p>
        <form onSubmit={submitNeedHelpMessage} className="mb0">
          <fieldset>
            <label htmlFor="message" className="input-wrapper">
              <span>Your Message:</span>
              <textarea name="message" className="mb1" onChange={updateMessage} value={message} />
            </label>
          </fieldset>
          <button className="button dark ml0" value="Submit">Send</button>
          <button className="button" onClick={clearHelper}>Cancel</button>
        </form>
      </div>
    );
  } else {
    if (props.currentUser.isAdvancedRole) {
      faqLink = (
        <a className="button dark stacked" href="https://dashboard.wikiedu.org/faq?topic=instructor_faq" target="blank">Instructor FAQ</a>
      );
    } else if (props.course.type === 'ClassroomProgramCourse') {
      faqLink = (
        <a className="button dark stacked" href="https://dashboard.wikiedu.org/faq?topic=student_faq" target="blank">Student FAQ</a>
      );
    }

    let searchHelpForum;
    if (props.course.type === 'ClassroomProgramCourse') {
      searchHelpForum = (
        <form target="_blank" action="/faq" acceptCharset="UTF-8" method="get">
          <input name="utf8" type="hidden" defaultValue="✓" />
          <input name="source" type="hidden" defaultValue="get_help_button" />
          <input type="text" name="search" id="get_help_search" defaultValue="" placeholder="Search Help Forum" />
          <button type="submit">
            <i className="icon icon-search" />
          </button>
        </form>
      );
    }


    content = (
      <div className="get-help-info">
        <p>
          <strong>
            Hi! if you need help with your Wikipedia project, you&apos;ve come
            to the right place!
          </strong>
        </p>
        {searchHelpForum}
        <p>
          Refer to our interactive training modules and
          external resources for help with your project.
        </p>

        <p>
          <a className="button dark" href="/training" target="blank">Interactive Training</a><br />
          {faqLink}
        </p>

        {contactStaff}
      </div>
    );
  }

  return (
    <div className="pop__container">
      <button className="dark button small" onClick={props.open}>Get Help</button>
      <div className={`pop ${props.is_open ? 'open' : ''}`}>
        <div className="pop__padded-content">
          {content}
        </div>
      </div>
    </div>
  );
};

GetHelpButton.propTypes = {
  currentUser: PropTypes.object,
  course: PropTypes.object,
  open: PropTypes.func,
  is_open: PropTypes.bool,
  alertSubmitting: PropTypes.bool,
  alertCreated: PropTypes.bool,
  actions: PropTypes.object
};

const mapStateToProps = state => ({
  alertSubmitting: state.needHelpAlert.submitted,
  alertCreated: state.needHelpAlert.created,
  contentExperts: getContentExperts(state),
  programManagers: getProgramManagers(state),
  staffUsers: getStaffUsers(state)
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators(AlertActions, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(Expandable(GetHelpButton));
