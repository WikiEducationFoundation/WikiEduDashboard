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

    const { heardFrom, referralDetails, primaryReason, primaryReasonDetails, whyHere, otherReason } = state;
    const body = {
      heardFrom,
      referralDetails,
      primaryReason,
      primaryReasonDetails,
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
      'association-or-conference': 'Which academic association or conference?',
      'social-media': 'Which social media?',
      listserv: 'Which listserv / email list?',
      'academic-paper': 'Which academic paper?',
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

            <input type="radio" name="heardFrom" id="association-or-conference" value="association-or-conference" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="association-or-conference">Academic association or conference</label><br/>

            <input type="radio" name="heardFrom" id="web" value="web" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="web">Web search</label><br/>

            <input type="radio" name="heardFrom" id="social-media" value="social-media" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="social-media">Social media</label><br/>

            <input type="radio" name="heardFrom" id="wiki-ed-email" value="wiki-ed-email" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="wiki-ed-email">Email from Wiki Education staff</label><br/>

            <input type="radio" name="heardFrom" id="listserv" value="listserv" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="listserv">Listserv / email list</label><br/>

            <input type="radio" name="heardFrom" id="wikipedia" value="wikipedia" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="wikipedia">On Wikipedia</label><br/>

            <input type="radio" name="heardFrom" id="academic-paper" value="academic-paper" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="academic-paper">Academic paper</label><br/>

            <input type="radio" name="heardFrom" id="heardFrom-other" value="other" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="heardFrom-other">Other</label><br/>

            {
              referralDetailsLabel && referralDetails
            }

            <br /><br />
            <label>{I18n.t('onboarding.supplementary.primary_reason')}</label>
            <input type="radio" name="primaryReason" id="primaryReason-real-world-impact" value="real-world-impact" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-real-world-impact">I wanted an assignment with real-world impact.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-misinformation" value="misinformation" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-misinformation">I wanted an assignment that tackles misinformation.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-ai" value="ai" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-ai">I wanted an assignment that tackles the challenges of AI.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-representation" value="representation" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-representation">I wanted an assignment that improves representation.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-evaluating-sources" value="evaluating-sources" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-evaluating-sources">I wanted an assignment that teaches my students how to evaluate sources.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-free-support" value="free-support" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-free-support">I wanted an assignment that includes free support for me and my students.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-something-new" value="something-new" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-something-new">I wanted to try something new.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-colleague-recommendation" value="colleague-recommendation" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-colleague-recommendation">My colleagues recommended the assignment to me.</label><br />

            <input type="radio" name="primaryReason" id="primaryReason-other" value="other" onChange={_handleFieldChange} />
            <label className="no-label" htmlFor="primaryReason-other" id="primaryReason-other-label">Other (please explain)</label><br />

            {
              state.primaryReason === 'other' && (
                <textarea className="form-control" name="primaryReasonDetails" id="primaryReasonDetails" aria-labelledby="primaryReason-other-label" defaultValue={state.primaryReasonDetails} onChange={_handleFieldChange} />
              )
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
            <label className="no-label" htmlFor="whyHere-other" id="whyHere-other-label">Other:</label><br />

            <textarea className="form-control" type="text" name="otherReason" id="otherReason" aria-labelledby="whyHere-other-label" defaultValue={state.otherReason} onChange={_handleFieldChange} />
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
