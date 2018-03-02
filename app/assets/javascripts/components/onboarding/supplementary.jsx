import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { browserHistory } from 'react-router';
import { connect } from "react-redux";

import API from '../../utils/api.js';
import { addNotification } from '../../actions/notification_actions.js';

const OnboardingSupplementary = createReactClass({
  propTypes: {
    returnToParam: PropTypes.string,
    addNotification: PropTypes.func
  },

  getInitialState() {
    return {
      heardFrom: ''
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

    const user = $('#react_root').data('current_user');

    return API.supplement({
      heardFrom: this.state.heardFrom,
      user_name: user.username
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
        <h1>{I18n.t('onboarding.supplementary.headline')}</h1>
        <form className="panel" onSubmit={this._handleSubmit} ref="form">
          <div className="form-group">
            <label>{I18n.t('onboarding.supplementary.heard_from')}</label>
            <textarea className="form-control" type="text" name="heardFrom" defaultValue={this.state.heardFrom} onChange={this._handleFieldChange.bind(this, 'heardFrom')} />
            <p className="form-help-text">
                {I18n.t('onboarding.supplementary.heard_from_helper')}
            </p>
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

export default connect(null, mapDispatchToProps)(OnboardingSupplementary);
