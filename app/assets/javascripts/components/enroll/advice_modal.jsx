import React from 'react';
import NewAccountButton from './new_account_button';
import PropTypes from 'prop-types';

const AdviceModal = ({ setModalShown, course, passcode, user }) => {
  return (
    <div className="wizard active undefined">
      <div className="container">
        <div className="wizard__panel active ">
          <div className="wizard_pop_header">
            <h3 className="heading-advice" >
              {I18n.t('application.sign_up_extended')}
            </h3>
            <a
              className="close-icon-advice icon-close"
              onClick={() => setModalShown(false)}
            />
          </div>
          <div className="pop_body">
            <h4 className="subheading-advice" >
              {I18n.t(
                'home.registration_advice.username_rules.heading'
              )}
            </h4>
            <ul className="list-advice">
              <li>
                {I18n.t(
                  'home.registration_advice.username_rules.avoid_offensive_usernames'
                )}
              </li>
              <li>
                {I18n.t(
                  'home.registration_advice.username_rules.represent_individual'
                )}
              </li>
            </ul>
            <h4 className="subheading-advice" >
              {I18n.t('home.registration_advice.additional_advice.heading')}
            </h4>
            <p className="list-advice2" >
              {I18n.t(
                'home.registration_advice.additional_advice.anonymous_username_recommendation'
              )}
            </p>
            <div>
              <NewAccountButton
                course={course}
                passcode={passcode}
                currentUser={user}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

AdviceModal.propTypes = {
  user: PropTypes.object,
  course: PropTypes.object,
  passcode: PropTypes.string,
  setModalShown: PropTypes.func,
};

export default AdviceModal;
