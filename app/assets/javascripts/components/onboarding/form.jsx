import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { browserHistory } from 'react-router';
import { connect } from "react-redux";

import API from '../../utils/api.js';
import { addNotification } from '../../actions/notification_actions.js';

const Form = createReactClass({
  propTypes: {
    currentUser: PropTypes.object,
    returnToParam: PropTypes.string,
    addNotification: PropTypes.func
  },

  getInitialState() {
    const user = this.props.currentUser;
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
      return browserHistory.push(`/onboarding/permissions?return_to=${decodeURIComponent(this.props.returnToParam)}`);
    }
    )
    .catch(() => {
      this.props.addNotification({
        message: I18n.t('error_500.explanation'),
        closable: true,
        type: 'error'
      });
      this.setState({ sending: false });
    });
  },

  render() {
    const submitText = this.state.sending ? 'Sending' : 'Submit';
    const disabled = this.state.sending;
    return (
      <div className="form">
        <h1>Let’s get some business out of the way.</h1>
        <form className="panel" onSubmit={this._handleSubmit} ref="form">
          <div className="form-group">
            <label>First and last name <span className="form-required-indicator">*</span></label>
            <input required className="form-control" type="text" name="name" defaultValue={this.state.name} onChange={this._handleFieldChange.bind(this, 'name')} />
            <p className="form-help-text">
              Your real name is not public. It is only seen by you, your instructor, and Wiki Ed admins.
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
            {submitText} <i className="icon icon-rt_arrow" />
          </button>
        </form>
      </div>
    );
  }
});

const mapDispatchToProps = { addNotification };

export default connect(null, mapDispatchToProps)(Form);
