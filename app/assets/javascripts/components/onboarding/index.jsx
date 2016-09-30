import React from 'react';
import TransitionGroup from 'react-addons-css-transition-group';
import API from '../../utils/api.coffee';
import NotificationActions from '../../actions/notification_actions.js';
import { Link, browserHistory } from 'react-router';

const getReturnToParam = function () {
  const returnTo = window.location.search.match(/return_to=([^&]*)/);
  return (returnTo && returnTo[1]) || '/';
};

const getCurrentUser = () => $('#react_root').data('current_user');

// Router root
const Root = React.createClass({
  propTypes: {
    children: React.PropTypes.object,
    location: React.PropTypes.object
  },

  render() {
    return (
      <div className="container">
        <TransitionGroup
          transitionName="fade"
          component="div"
          transitionEnterTimeout={250}
          transitionLeaveTimeout={250}
        >
          {React.cloneElement(this.props.children, { key: this.props.location.pathname })}
        </TransitionGroup>
      </div>
    );
  }
});

// Intro slide
const Intro = React.createClass({
  getInitialState() {
    return { user: getCurrentUser() };
  },

  render() {
    return (
      <div className="intro text-center">
        <h1>Hi {this.state.user.real_name || this.state.user.username}</h1>
        <p>We’re excited that you’re here!</p>
        <Link to={{ pathname: '/onboarding/form', query: { return_to: decodeURIComponent(getReturnToParam()) } }} className="button border inverse-border">Start <i className="icon icon-rt_arrow"></i></Link>
      </div>
    );
  }
});

// Form slide
const Form = React.createClass({
  getInitialState() {
    const user = getCurrentUser();
    return {
      started: false,
      user,
      name: user.real_name,
      email: user.email,
      instructor: (user.permissions !== null) ? String(user.permission === 2) : null
    };
  },

  // Update state when input fields change
  _handleFieldChange(field, e) {
    const obj = {};
    obj[field] = e.target.value;
    return this.setState(obj);
  },

  _handleSubmit(e) {
    e.preventDefault();
    this.setState({ sending: true });
    this.state.user.instructor = this.state.instructor === 'true';
    $('#react_root').data('current_user', this.state.user);

    return API.onboard({
      real_name: this.state.name,
      email: this.state.email,
      instructor: this.state.instructor === 'true'
    })
    .then(() => {
      return browserHistory.push(`/onboarding/permissions?return_to=${decodeURIComponent(getReturnToParam())}`);
    }
    )
    .catch(function (err, ...args) {
      NotificationActions.addNotification({
        message: I18n.t('error_500.explanation'),
        closable: true,
        type: 'error'
      });
      this.setState({ sending: false });
      return console.log(err, args);
    });
  },

  render() {
    let submitText = this.state.sending ? 'Sending' : 'Submit';
    let disabled = this.state.sending;
    return (
      <div className="form">
        <h1>Let’s get some business out of the way.</h1>
        <form className="panel" onSubmit={this._handleSubmit} ref="form">
          <div className="form-group">
            <label>Full name <span className="form-required-indicator">*</span></label>
            <input required className="form-control" type="text" name="name" defaultValue={this.state.name} onChange={this._handleFieldChange.bind(this, 'name')} />
            <p className="form-help-text">
              Your real name is not public. Its only seen by you, your instructor, and Wiki Ed admins.
            </p>
          </div>
          <div className="form-group">
            <label>Email <span className="form-required-indicator">*</span></label>
            <input required className="form-control" type="email" name="email" defaultValue={this.state.email} onChange={this._handleFieldChange.bind(this, 'email')} />
            <p className="form-help-text">
              Your email is only used for notifications and will not be shared.
            </p>
          </div>
          <div className="form-group">
            <label>Are you an instructor? <span className="form-required-indicator">*</span></label>
            <div className="radio-group">
              <div className={`radio-wrapped ${this.state.instructor === 'true' ? 'checked' : ''}`}>
                <label>
                  <input required type="radio" name="instructor" value="true" defaultChecked={this.state.instructor === 'true'} onChange={this._handleFieldChange.bind(this, 'instructor')} />
                  Yes
                </label>
              </div>
              <div className={`radio-wrapped ${this.state.instructor === 'false' ? 'checked' : ''}`}>
                <label>
                  <input required type="radio" name="instructor" value="false" defaultChecked={this.state.instructor === 'false'} onChange={this._handleFieldChange.bind(this, 'instructor')} />
                  No
                </label>
              </div>
            </div>
          </div>
          <button disabled={disabled} type="submit" className="button dark right">
            {submitText} <i className="icon icon-rt_arrow"></i>
          </button>
        </form>
      </div>
    );
  }
});

// Permissions slide
const Permissions = React.createClass({
  render() {
    let slide;

    if (getCurrentUser().instructor) {
      slide = (
        <div className="intro permissions">
          <h1>Permissions</h1>
          <p>
            Once you´ve signed in, this website will make automatic edits using your Wikipedia account, reflecting actions you take here. Your account will be used to update wiki pages when:
          </p>
          <ul>
            <li>you submit a Wikipedia classroom assignment or make edits to your course page</li>
            <li>you add or remove someone from a course</li>
            <li>you assign articles to students</li>
            <li>you send public messages to students</li>
          </ul>
          <p>All course content you contribute to to this website will be freely available under the <a href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike license</a> (the same one used by Wikipedia).</p>
          <Link to={{ pathname: '/onboarding/finish', query: { return_to: getReturnToParam() } }} className="button border inverse-border">
            Finish <i className="icon icon-rt_arrow"></i>
          </Link>
        </div>
      );
    } else {
      slide = (
        <div className="intro permissions">
          <h1>Permissions</h1>
          <p>
            Once you´ve signed in, this website will make automatic edits using your Wikipedia account, reflecting actions you take here. Your account will be used to update wiki pages to:
          </p>
          <ul>
            <li>set up a sandbox page where you can practice editing</li>
            <li>adjust your account preferences to enable VisualEditor</li>
            <li>add a standard message on your userpage so that others know what course you are part of</li>
            <li>add standard messages to the Talk pages of articles you´re editing or reviewing</li>
            <li>update your course´s wiki page when you join the course or choose an assignment topic</li>
          </ul>
          <p>All course content you contribute to to this website will be freely available under the <a href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike license</a> (the same one used by Wikipedia).</p>
          <Link to={{ pathname: '/onboarding/finish', query: { return_to: getReturnToParam() } }} className="button border inverse-border">
            Finish <i className="icon icon-rt_arrow"></i>
          </Link>
        </div>
      );
    }

    return slide;
  }
});

// Finished slide
const Finished = React.createClass({

  getInitialState() {
    return {};
  },

  // When this route loads, wait a second then redirect out to the return_to param (or root)
  componentDidMount() {
    return this.state.timeout = setTimeout(() => {
      const returnTo = getReturnToParam();
      return window.location = decodeURIComponent(returnTo);
    }
    , 750);
  },

  // clear the timeout just to be safe
  componentWillUnmount() {
    return clearTimeout(this.state.timeout);
  },

  render() {
    return (
      <div className="intro">
        <h1>You´re all set. Thank you.</h1>
        <h2>Loading...</h2>
      </div>
    );
  }
});

export default { Root, Intro, Form, Permissions, Finished };
