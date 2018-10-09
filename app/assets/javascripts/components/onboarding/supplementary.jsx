import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { browserHistory } from 'react-router';
import { connect } from 'react-redux';

import OnboardAPI from '../../utils/onboarding_utils.js';
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

    return OnboardAPI.supplement({
      heardFrom: this.state.heardFrom,
      whyHere: this.state.whyHere,
      otherReason: this.state.otherReason,
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
        <h1>{I18n.t('onboarding.supplementary.header')}</h1>
        <form id="supplementary" className="panel" onSubmit={this._handleSubmit} ref="form">
          <div className="form-group">
            <label>{I18n.t('onboarding.supplementary.where_did_you_hear')}</label>
            <textarea className="form-control" type="text" name="heardFrom" defaultValue={this.state.heardFrom} onChange={this._handleFieldChange.bind(this, 'heardFrom')} />
            <br /><br />
            <label>{I18n.t('onboarding.supplementary.why_are_you_here')}</label>
            <input type="radio" name="whyHere" value="teach this term" onChange={this._handleFieldChange.bind(this, 'whyHere')} /> I want to teach with Wikipedia <strong>this term</strong><br />
            <input type="radio" name="whyHere" value="teach next term" onChange={this._handleFieldChange.bind(this, 'whyHere')} /> I want to teach with Wikipedia <strong>next term</strong><br />
            <input type="radio" name="whyHere" value="learn about teaching" onChange={this._handleFieldChange.bind(this, 'whyHere')} /> I want to learn more about teaching with Wikipedia<br />
            <input type="radio" name="whyHere" value="other" onChange={this._handleFieldChange.bind(this, 'whyHere')} /> Other:<br />
            <textarea className="form-control" type="text" name="otherReason" defaultValue={this.state.otherReason} onChange={this._handleFieldChange.bind(this, 'otherReason')} />
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
