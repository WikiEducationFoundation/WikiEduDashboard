import React from 'react';
import Expandable from '../high_order/expandable.cjsx';
import UserStore from '../../stores/user_store.coffee';
import AlertsStore from '../../stores/alerts_store.coffee';
import AlertActions from '../../actions/alert_actions.js';

const getState = () =>
  ({
    contentExperts: UserStore.getFiltered({ content_expert: true }),
    programManagers: UserStore.getFiltered({ program_manager: true }),
    alertSubmitting: AlertsStore.getNeedHelpAlertSubmitting(),
    alertCreated: AlertsStore.getNeedHelpAlertSubmitted()
  })
;

const GetHelpButton = React.createClass({
  displayName: 'GetHelpButton',

  propTypes: {
    key: React.PropTypes.string,
    current_user: React.PropTypes.object,
    course: React.PropTypes.object,
    open: React.PropTypes.func,
    is_open: React.PropTypes.bool
  },

  mixins: [UserStore.mixin, AlertsStore.mixin],

  getInitialState() {
    const state = getState();
    state.selectedTargetUser = null;
    state.message = null;
    return state;
  },

  getKey() {
    return this.props.key;
  },

  stop(e) {
    return e.stopPropagation();
  },

  storeDidChange() {
    return this.setState(getState());
  },

  reset(e) {
    e.preventDefault();
    this.setState({
      message: '',
      selectedTargetUser: null
    });
    this.props.open();
    setTimeout(() => {
      AlertActions.resetNeedHelpAlert();
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
    AlertActions.submitNeedHelpAlert(messageData);
  },

  render() {
    let programManagers;
    let contentExperts;
    let targetUsers;
    let content;
    let faqLink;

    contentExperts = this.state.contentExperts.map((user) => {
      return (
        <span className="content-experts" key={user.username}>
          <a href="#" className="content-expert-link" onClick={(e) => this.updateTargetUser(user, e)}>{user.username}</a> (Content Expert)
          <br />
        </span>
      );
    });

    if (this.props.current_user.role > 0) {
      programManagers = this.state.programManagers.map((user) => {
        return (
          <span className="program-managers" key={user.username}>
            <a href="#" className="program-manager-link" onClick={(e) => this.updateTargetUser(user, e)}>{user.username}</a> (Program Manager)
            <br />
          </span>
        );
      });
    } else {
      programManagers = [];
    }

    if (programManagers.length > 0 || contentExperts.length > 0) {
      targetUsers = (
        <p className="target-users">
          If you still need help, reach out to the appropriate person:
          <br />
          {contentExperts}
          {programManagers}
        </p>
      );
    }

    if (this.state.alertSubmitting) {
      content = (
        <div className="text-center get-help-submitting">
          <strong>Sending message...</strong>
        </div>
      );
    } else if (this.state.alertCreated) {
      content = (
        <div className="text-center get-help-submitted">
          <strong>
            Message sent!
            <br />
            We'll get back to you within 1 business day. Be sure to check your email for a response.
            <br />
            <a href="#" onClick={this.reset}>Ok</a>
          </strong>
        </div>
      );
    } else if (this.state.selectedTargetUser) {
      content = (
        <div className="get-help-form">
          <p><strong>To: {this.state.selectedTargetUser.username}</strong></p>
          <form onSubmit={this.submitNeedHelpMessage} className="mb0">
            <input name="targetUser" type="hidden" defaultValue="" value={this.state.selectedTargetUser.id} />
            <fieldset>
              <label htmlFor="message" className="input-wrapper">
                <span>Your Message:</span>
                <textarea name="message" className="mb1" onChange={this.updateMessage} defaultValue="" value={this.state.message} />
              </label>
            </fieldset>
            <button className="button dark ml0" value="Submit">Send</button>
            <button className="button" onClick={this.clearHelper}>Cancel</button>
          </form>
        </div>
      );
    } else {
      if (this.props.current_user.role > 0) {
        faqLink = (
          <a href="http://ask.wikiedu.org/questions/scope:all/sort:activity-desc/tags:instructorfaq/page:1/" target="blank">FAQ</a>
        );
      } else {
        faqLink = (
          <a href="http://ask.wikiedu.org/questions/scope:all/sort:activity-desc/tags:studentfaq/page:1/" target="blank">FAQ</a>
        );
      }

      content = (
        <div className="get-help-info">
          <p>
            <strong>
              Hi, if you need help with your Wikipedia assignment, you've come
              to the right place!
            </strong>
          </p>

          <form target="_blank" action="/ask" acceptCharset="UTF-8" method="get">
            <input name="utf8" type="hidden" defaultValue="✓" />
            <input type="text" name="q" id="q" defaultValue="" placeholder="Search Help Forum" />
            <button type="submit">
              <i className="icon icon-search"></i>
            </button>
          </form>

          <p>
            You may also refer to our interactive training modules and
            external resources for help with your assignment.
          </p>

          <p>
            <a href="/training" target="blank">Interactive Training</a><br />
            {faqLink}
          </p>

          {targetUsers}
        </div>
      );
    }

    return (
      <div className="pop__container">
        <button className="dark button small" onClick={this.props.open}>Get Help</button>
        <div className={`pop ${this.props.is_open ? ' open' : ''}`}>
          <div className="pop__padded-content">
            {content}
          </div>
        </div>
      </div>
    );
  }
});

export default Expandable(GetHelpButton);
