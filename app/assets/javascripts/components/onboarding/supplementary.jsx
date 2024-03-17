import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import withRouter from '../util/withRouter';
import { connect } from 'react-redux';

import OnboardAPI from '../../utils/onboarding_utils.js';
import { addNotification } from '../../actions/notification_actions.js';

const NoLabelStyle = {
  display: 'inline',
  fontWeight: 'normal',
  color: '#6a6a6a'
};

export const OnboardingSupplementary = createReactClass({
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
  _handleFieldChange(e) {
    const { name, value } = e.target;
    return this.setState({ [name]: value });
  },

  _handleSubmit(e) {
    e.preventDefault();
    this.setState({ sending: true });

    const user = this.props.user;
    const { heardFrom, referralDetails, whyHere, otherReason } = this.state;
    const body = {
      heardFrom,
      referralDetails,
      whyHere,
      otherReason,
      user_name: user.username
    };

    return OnboardAPI.supplement(body)
    .then(() => {
      const returnTo = decodeURIComponent(this.props.returnToParam);
      const nextUrl = `/onboarding/permissions?return_to=${returnTo}`;
      return this.props.router.navigate(nextUrl);
    })
    .catch(() => {
      this.props.addNotification({
        message: I18n.t('error_500.explanation'),
        closable: true,
        type: 'error'
      });
      this.setState({ sending: false });
    });
  },

  _getReferralDetailsLabel() {
    const selected = this.state.heardFrom;
    const options = {
      colleague: 'Colleague\'s name:',
      association: 'Academic association\'s name:',
      conference: 'Conference name:',
      workshop: 'University workshop name:',
      other: 'Other way you heard about us:'
    };

    return options[selected];
  },

  render() {
    const submitText = this.state.sending ? 'Sending' : 'Submit';
    const disabled = this.state.sending;
    const referralDetailsLabel = this._getReferralDetailsLabel();
    const referralDetails = (
      <div>
        <br />
        <label htmlFor="referralDetails">{referralDetailsLabel}</label>
        <textarea id="referralDetails" className="form-control" name="referralDetails" onChange={this._handleFieldChange} />
      </div>
    );

    return (
      <div className="form">
        <h1>{I18n.t('onboarding.supplementary.header')}</h1>
        <form id="supplementary" className="panel" onSubmit={this._handleSubmit} ref="form">
          <div className="form-group">
            <label htmlFor="heardFrom">{I18n.t('onboarding.supplementary.where_did_you_hear')}</label>

            <input type="radio" name="heardFrom" id="colleague" value="colleague" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="colleague">A colleague referred me</label><br/>

            <input type="radio" name="heardFrom" id="association" value="association" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="association">Academic association</label><br/>

            <input type="radio" name="heardFrom" id="conference" value="conference" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="conference">Conference</label><br/>

            <input type="radio" name="heardFrom" id="workshop" value="workshop" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="workshop">University workshop</label><br/>

            <input type="radio" name="heardFrom" id="web" value="web" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="web">Web Search</label><br/>

            <input type="radio" name="heardFrom" id="twitter" value="twitter" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="twitter">Twitter</label><br/>

            <input type="radio" name="heardFrom" id="facebook" value="facebook" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="facebook">Facebook</label><br/>

            <input type="radio" name="heardFrom" id="heardFrom-other" value="other" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="heardFrom-other">Other</label><br/>


            {
              referralDetailsLabel && referralDetails
            }
            <br /><br />
            <label>{I18n.t('onboarding.supplementary.why_are_you_here')}</label>
            <input type="radio" name="whyHere" id="teachThisTerm" value="teach this term" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="teachThisTerm">I want to teach with Wikipedia <strong>this term</strong></label><br />

            <input type="radio" name="whyHere" id="teachNextTerm" value="teach next term" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="teachNextTerm">I want to teach with Wikipedia <strong>next term</strong></label><br />

            <input type="radio" name="whyHere" id="learnAboutTeaching" value="learn about teaching" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="learnAboutTeaching">I want to learn more about teaching with Wikipedia</label><br />

            <input type="radio" name="whyHere" id="whyHere-other" value="other" onChange={this._handleFieldChange} />
            <label style={NoLabelStyle} htmlFor="whyHere-other">Other:</label><br />

            <textarea className="form-control" type="text" name="otherReason" defaultValue={this.state.otherReason} onChange={this._handleFieldChange.bind(this, 'otherReason')} />
          </div>
          <button disabled={disabled} type="submit" className="button dark right">
            {submitText} <i className="icon3 icon-rt_arrow" />
          </button>
        </form>
      </div>
    );
  }
});

const mapDispatchToProps = { addNotification };
const mapStateToProps = state => ({
  user: state.currentUserFromHtml
});

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(OnboardingSupplementary));
