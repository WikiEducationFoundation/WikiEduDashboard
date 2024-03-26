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

            <input type="radio" name="heardFrom" id="colleague" value="colleague" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="colleague">A colleague referred me</label><br/>

            <input type="radio" name="heardFrom" id="association" value="association" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="association">Academic association</label><br/>

            <input type="radio" name="heardFrom" id="conference" value="conference" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="conference">Conference</label><br/>

            <input type="radio" name="heardFrom" id="workshop" value="workshop" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="workshop">University workshop</label><br/>

            <input type="radio" name="heardFrom" id="web" value="web" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="web">Web Search</label><br/>

            <input type="radio" name="heardFrom" id="twitter" value="twitter" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="twitter">Twitter</label><br/>

            <input type="radio" name="heardFrom" id="facebook" value="facebook" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="facebook">Facebook</label><br/>

            <input type="radio" name="heardFrom" id="heardFrom-other" value="other" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="heardFrom-other">Other</label><br/>


            {
              referralDetailsLabel && referralDetails
            }

            <br /><br />
            <label>{I18n.t('onboarding.supplementary.why_are_you_here')}</label>
            <input type="radio" name="whyHere" id="teachThisTerm" value="teach this term" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="teachThisTerm">I want to teach with Wikipedia <strong>this term</strong></label><br />

            <input type="radio" name="whyHere" id="teachNextTerm" value="teach next term" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="teachNextTerm">I want to teach with Wikipedia <strong>next term</strong></label><br />

            <input type="radio" name="whyHere" id="learnAboutTeaching" value="learn about teaching" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="learnAboutTeaching">I want to learn more about teaching with Wikipedia</label><br />

            <input type="radio" name="whyHere" id="whyHere-other" value="other" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="whyHere-other">Other:</label><br />

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
