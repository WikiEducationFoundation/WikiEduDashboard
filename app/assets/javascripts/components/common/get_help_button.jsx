import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import * as AlertActions from '../../actions/alert_actions.js';
import { getStaffUsers, getProgramManagers, getContentExperts } from '../../selectors';

import Expandable from '../high_order/expandable.jsx';

const GetHelpButton = createReactClass({
  displayName: 'GetHelpButton',

  propTypes: {
    currentUser: PropTypes.object,
    course: PropTypes.object,
    open: PropTypes.func,
    is_open: PropTypes.bool,
    alertSubmitting: PropTypes.bool,
    alertCreated: PropTypes.bool,
    actions: PropTypes.object
  },

  getInitialState() {
    return {
      selectedTargetUser: null,
      message: ''
    };
  },

  // This component expects to be created with key='get_help'.
  // The getKey function is used by Expandable.
  getKey() {
    return 'get_help';
  },

  stop(e) {
    return e.stopPropagation();
  },


  reset(e) {
    e.preventDefault();
    this.setState({
      message: '',
      selectedTargetUser: null
    });
    this.props.open(e);
    setTimeout(() => {
      this.props.actions.resetNeedHelpAlert();
    }, 500);
  },

  updateTargetUser(targetUser, e) {
    e.preventDefault();
    this.setState({ selectedTargetUser: targetUser });
  },

  clearHelper(e) {
    e.preventDefault();
    this.setState({ selectedTargetUser: null });
  },

  updateMessage(e) {
    this.setState({ message: e.target.value });
  },

  submitNeedHelpMessage(e) {
    e.preventDefault();
    const messageData = {
      target_user_id: this.state.selectedTargetUser.id,
      message: this.state.message,
      course_id: this.props.course.id
    };
    this.props.actions.submitNeedHelpAlert(messageData);
  },

  wikipediaHelpUser() {
    if (this.props.contentExperts && this.props.contentExperts.length > 0) {
      return this.props.contentExperts[0];
    } else if (this.props.programManagers && this.props.programManagers.length > 0) {
      return this.props.programManagers[0];
    }
    return this.props.staffUsers[0];
  },

  programHelpUser() {
    if (this.props.programManagers && this.props.programManagers.length > 0) {
      return this.props.programManagers[0];
    } else if (this.props.contentExperts && this.props.contentExperts.length > 0) {
      return this.props.contentExperts[0];
    }
    return this.props.staffUsers[0];
  },

  dashboardHelpUser() {
    return { username: 'Technical help staff' };
  },

  render() {
    let content;
    let faqLink;

    let wikipediaHelpButton;
    let programHelpButton;
    let dashboardHelpButton;

    // Only show these contact buttons if there are staff assigned to the course.
    if (this.props.staffUsers && this.props.staffUsers.length > 0) {
      // Show the Wikipedia help button to everyone.
      const wikipediaHelpUser = this.wikipediaHelpUser();
      wikipediaHelpButton = (
        <span className="contact-wikipedia-help" key={`${wikipediaHelpUser.username}-wikipedia-help`}>
          <a href="#" className="wikipedia-help-link button dark small stacked" onClick={e => this.updateTargetUser(wikipediaHelpUser, e)}>question about editing Wikipedia</a>
          <br />
        </span>
      );

      // Show the program help button only to instructors and other non-students.
      if (this.props.currentUser.isAdvancedRole) {
        const programHelpUser = this.programHelpUser();
        programHelpButton = (
          <span className="contact-program-help" key={`${programHelpUser.username}-program-help`}>
            <a href="#" className="program-help-link button dark stacked small" onClick={e => this.updateTargetUser(programHelpUser, e)}>question about Wiki Ed or your assignment</a>
            <br />
          </span>
        );
      }

      // Show the dashboard help button to everyone.
      const dashboardHelpUser = this.dashboardHelpUser();
      dashboardHelpButton = (
        <span className="contact-dashboard-help" key={`${dashboardHelpUser.username}-dashboard-help`}>
          <a href="#" className="dashboard-help-link button dark stacked small" onClick={e => this.updateTargetUser(dashboardHelpUser, e)}>question about the dashboard</a>
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

    if (this.props.alertSubmitting) {
      content = (
        <div className="text-center get-help-submitting">
          <strong>Sending message...</strong>
        </div>
      );
    } else if (this.props.alertCreated) {
      content = (
        <div className="get-help-submitted">
          <p className="text-center"><strong>Message sent!</strong></p>
          <p>
            We&apos;ll get back to you within 1 business day. Be sure to check your email for a response.
          </p>
          <a href="#" className="button" onClick={this.reset}>Ok</a>
        </div>
      );
    } else if (this.state.selectedTargetUser) {
      content = (
        <div className="get-help-form">
          <p><strong>To: {this.state.selectedTargetUser.username}</strong></p>
          <form onSubmit={this.submitNeedHelpMessage} className="mb0">
            <input name="targetUser" type="hidden" value={this.state.selectedTargetUser.id} />
            <fieldset>
              <label htmlFor="message" className="input-wrapper">
                <span>Your Message:</span>
                <textarea name="message" className="mb1" onChange={this.updateMessage} value={this.state.message} />
              </label>
            </fieldset>
            <button className="button dark ml0" value="Submit">Send</button>
            <button className="button" onClick={this.clearHelper}>Cancel</button>
          </form>
        </div>
      );
    } else {
      if (this.props.currentUser.isAdvancedRole) {
        faqLink = (
          <a className="button dark stacked" href="https://dashboard.wikiedu.org/faq?topic=instructor_faq" target="blank">Instructor FAQ</a>
        );
      } else if (this.props.course.type === 'ClassroomProgramCourse') {
        faqLink = (
          <a className="button dark stacked" href="https://dashboard.wikiedu.org/faq?topic=student_faq" target="blank">Student FAQ</a>
        );
      }

      let searchHelpForum;
      if (this.props.course.type === 'ClassroomProgramCourse') {
        searchHelpForum = (
          <form target="_blank" action="/faq" acceptCharset="UTF-8" method="get">
            <input name="utf8" type="hidden" defaultValue="✓" />
            <input name="source" type="hidden" defaultValue="get_help_button" />
            <input type="text" name="search" id="search" defaultValue="" placeholder="Search Help Forum" />
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
        <button className="dark button small" onClick={this.props.open}>Get Help</button>
        <div className={`pop ${this.props.is_open ? 'open' : ''}`}>
          <div className="pop__padded-content">
            {content}
          </div>
        </div>
      </div>
    );
  }
});

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
