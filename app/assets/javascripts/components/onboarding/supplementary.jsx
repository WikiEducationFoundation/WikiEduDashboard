import React, { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import OnboardAPI from '../../utils/onboarding_utils.js';
import { addNotification } from '../../actions/notification_actions.js';

export const OnboardingSupplementary = (props) => {
  const formRef = useRef(null);
  const navigate = useNavigate();
  const [state, setState] = useState({
    heardFrom: '',
    sending: false,
    referralDetailsLabel: '',
  });

  const _handleFieldChange = (e) => {
    const { name, value } = e.target;
    setState(prevState => ({ ...prevState, [name]: value }));
  };

  const _handleSubmit = (e) => {
    e.preventDefault();
    setState(prevState => ({ ...prevState, sending: true }));

    const { heardFrom, referralDetails, whyHere, otherReason } = state;
    const body = {
      heardFrom,
      referralDetails,
      whyHere,
      otherReason,
      user_name: props.user.username
    };

    return OnboardAPI.supplement(body)
      .then(() => {
        const returnTo = decodeURIComponent(props.returnToParam);
        const nextUrl = `/onboarding/permissions?return_to=${returnTo}`;
        return navigate(nextUrl);
      })
      .catch(() => {
        props.addNotification({
          message: I18n.t('error_500.explanation'),
          closable: true,
          type: 'error'
        });
        setState(prevState => ({ ...prevState, sending: false }));
      });
  };

  const _getReferralDetailsLabel = () => {
    const selected = state.heardFrom;
    const options = {
      colleague: 'Colleague\'s name:',
      association: 'Academic association\'s name:',
      conference: 'Conference name:',
      workshop: 'University workshop name:',
      other: 'Other way you heard about us:'
    };

    return options[selected];
  };

  const submitText = state.sending ? 'Sending' : 'Submit';
  const disabled = state.sending;
  const referralDetailsLabel = _getReferralDetailsLabel();
  const referralDetails = (
    <div>
      <br />
      <label htmlFor="referralDetails">{referralDetailsLabel}</label>
      <textarea id="referralDetails" className="form-control" name="referralDetails" onChange={_handleFieldChange} />
    </div>
  );

  return (
    <div className="form">
      <h1>{I18n.t('onboarding.supplementary.header')}</h1>
      <form id="supplementary" className="panel" onSubmit={_handleSubmit} ref={formRef}>
        <div className="form-group">
          <label htmlFor="heardFrom">{I18n.t('onboarding.supplementary.where_did_you_hear')}</label>
          <input type="radio" name="heardFrom" value="colleague" onChange={_handleFieldChange} />A colleague referred me<br/>
          <input type="radio" name="heardFrom" value="association" onChange={_handleFieldChange} />Academic association<br/>
          <input type="radio" name="heardFrom" value="conference" onChange={_handleFieldChange} />Conference<br/>
          <input type="radio" name="heardFrom" value="workshop" onChange={_handleFieldChange} />University workshop<br/>
          <input type="radio" name="heardFrom" value="web" onChange={_handleFieldChange} />Web Search<br/>
          <input type="radio" name="heardFrom" value="twitter" onChange={_handleFieldChange} />Twitter<br/>
          <input type="radio" name="heardFrom" value="facebook" onChange={_handleFieldChange} />Facebook<br/>
          <input type="radio" name="heardFrom" value="other" onChange={_handleFieldChange} />Other<br/>
          {
            referralDetailsLabel && referralDetails
          }
          <br /><br />
          <label>{I18n.t('onboarding.supplementary.why_are_you_here')}</label>
          <input type="radio" name="whyHere" value="teach this term" onChange={_handleFieldChange} /> I want to teach with Wikipedia <strong>this term</strong><br />
          <input type="radio" name="whyHere" value="teach next term" onChange={_handleFieldChange} /> I want to teach with Wikipedia <strong>next term</strong><br />
          <input type="radio" name="whyHere" value="learn about teaching" onChange={_handleFieldChange} /> I want to learn more about teaching with Wikipedia<br />
          <input type="radio" name="whyHere" value="other" onChange={_handleFieldChange} /> Other:<br />
          <textarea className="form-control" type="text" name="otherReason" defaultValue={state.otherReason} onChange={_handleFieldChange} />
        </div>
        <button disabled={disabled} type="submit" className="button dark right">
          {submitText} <i className="icon3 icon-rt_arrow" />
        </button>
      </form>
    </div>
  );
};

OnboardingSupplementary.propTypes = {
  returnToParam: PropTypes.string,
  addNotification: PropTypes.func,
  user: PropTypes.object,
};

const mapDispatchToProps = { addNotification };
const mapStateToProps = state => ({
  user: state.currentUserFromHtml
});

export default connect(mapStateToProps, mapDispatchToProps)(OnboardingSupplementary);
