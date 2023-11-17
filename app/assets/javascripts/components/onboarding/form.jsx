import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import withRouter from '../util/withRouter';
import { connect } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import OnboardAPI from '../../utils/onboarding_utils.js';
import { addNotification as notify } from '../../actions/notification_actions.js';

const isEnrollUrl = (returnToParam) => {
  if (returnToParam.includes('/enroll')) {
    return true;
  }
  if (returnToParam.includes('%2Fenroll')) {
    return true;
  }
  return false;
};

const Form = ({ currentUser, returnToParam, addNotification }) => {
  const [state, setState] = useState({
    started: false,
    user: currentUser,
    name: currentUser.real_name,
    email: currentUser.email,
    instructor:
      currentUser.permissions !== null
        ? String(currentUser.permission === 2)
        : null,
    sending: false,
  });

  const [instructorFormClass, setInstructorFormClass] = useState('');

  const [submitText, setSubmitText] = useState('Submit');
  const [disabled, setDisabled] = useState(false);

  const navigate = useNavigate();

  // Update state when input fields change
  const handleFieldChange = (field, e) => {
    setState(prevState => ({
      ...prevState,
      [field]: e.target.value,
    }));
  };

  const formRef = useRef();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setState(prevState => ({ ...prevState, sending: true }));
    state.user.instructor = state.instructor === 'true';
    try {
      await OnboardAPI.onboard({
        real_name: state.name,
        email: state.email,
        instructor: state.instructor === 'true',
      });

      const destination = state.instructor === 'true' ? 'supplementary' : 'permissions';

      navigate(
        `/onboarding/${destination}?return_to=${decodeURIComponent(
          returnToParam
        )}`
      );
    } catch (err) {
      addNotification({
        message: I18n.t('error_500.explanation'),
        closable: true,
        type: 'error',
      });
      setState(prevState => ({ ...prevState, sending: false }));
    }
  };

  useEffect(() => {
    setSubmitText(state.sending ? 'Sending' : 'Submit');
    setDisabled(state.sending);
  }, [state]);

  useEffect(() => {
    // Hide the 'are you an instructor' question if user is returning to an enrollment URL.
    // That means they are trying to join a course as a student, so assume that they are one.
    setInstructorFormClass(
      isEnrollUrl(returnToParam) ? 'form-group hidden' : 'form-group'
    );
  }, [returnToParam]);

  return (
    <div className="form">
      <h1>Let&apos;s get some business out of the way.</h1>
      <form className="panel" onSubmit={e => handleSubmit(e)} ref={formRef}>
        <div className="form-group">
          <label>
            First and last name
            <span className="form-required-indicator">*</span>
          </label>
          <input
            required
            className="form-control"
            type="text"
            name="name"
            defaultValue={state.name}
            onChange={e => handleFieldChange('name', e)}
          />
          <p className="form-help-text">
            Your real name is not public. It is only seen by you, your
            instructor, and Wiki Education admins.
          </p>
        </div>
        <div className="form-group">
          <label>
            Email <span className="form-required-indicator">*</span>
          </label>
          <input
            required
            className="form-control"
            type="email"
            name="email"
            defaultValue={state.email}
            onChange={e => handleFieldChange('email', e)}
          />
          <p className="form-help-text">
            Your email is only used for notifications and will not be shared.
          </p>
        </div>
        <div className={instructorFormClass}>
          <label>
            Are you an instructor?
            <span className="form-required-indicator">*</span>
          </label>
          <div className="radio-group">
            <div
              className={`radio-wrapped ${
                state.instructor === 'true' ? 'checked' : ''
              }`}
            >
              <label>
                <input
                  required
                  type="radio"
                  name="instructor"
                  value="true"
                  defaultChecked={state.instructor === 'true'}
                  onChange={e => handleFieldChange('instructor', e)}
                />
                Yes
              </label>
            </div>
            <div
              className={`radio-wrapped ${
                state.instructor === 'false' ? 'checked' : ''
              }`}
            >
              <label>
                <input
                  required
                  type="radio"
                  name="instructor"
                  value="false"
                  defaultChecked={state.instructor === 'false'}
                  onChange={e => handleFieldChange('instructor', e)}
                />
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
};

Form.propTypes = {
  currentUser: PropTypes.object,
  returnToParam: PropTypes.string,
  addNotification: PropTypes.func,
};

const mapDispatchToProps = { notify };

export default withRouter(connect(null, mapDispatchToProps)(Form));
