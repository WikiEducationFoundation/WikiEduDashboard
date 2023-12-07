import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import NewAccountModal from './new_account_modal.jsx';
import { canUserCreateAccount } from '@components/util/helpers';

const NewAccountButton = ({ course, passcode, currentUser }) => {
  const [showModal, setShowModal] = useState(false);
  const [disabled, setDisabled] = useState(false);
  const [isHovered, setIsHovered] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      const canCreate = await canUserCreateAccount();
      setDisabled(!canCreate);
    };

    fetchData();
  }, []);

  const openModal = () => {
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
  };

  if (!course.account_requests_enabled) {
    return (
      <>
        <a
          data-method="post"
          href={`/users/auth/mediawiki_signup?origin=${window.location}`}
          className={`button auth signup border margin ${disabled ? 'disabled' : ''}`}
          onMouseEnter={() => setIsHovered(true)} onMouseLeave={() => setIsHovered(false)}
          style={{
            marginRight: '0'
          }}
        >
          <i className={`icon ${isHovered ? 'icon-wiki-white' : ' icon-wiki-purple'}`} />
          {I18n.t('application.sign_up_extended')}
        </a>
        {disabled && (
          <div className="tooltip-trigger tooltip-small">
            <img className="info-img" src="/assets/images/info.svg" alt="tooltip default logo" />
            <div className="tooltip dark large">
              <p>
                {I18n.t('error.ip_blocked')}
              </p>
            </div>
          </div>
        )}
      </>
    );
  }

  let buttonOrModal;
  if (showModal) {
    buttonOrModal = <NewAccountModal course={course} passcode={passcode} closeModal={closeModal} currentUser={currentUser} />;
  } else {
    buttonOrModal = (
      <button onClick={openModal} key="request_account" className="button auth signup border margin request_accounts">
        <i className="icon-wiki-purple icon" /> {currentUser.isInstructor ? I18n.t('application.request_account_create') : I18n.t('application.request_account')}
      </button>
    );
  }

  return buttonOrModal;
};

NewAccountButton.propTypes = {
  course: PropTypes.object.isRequired,
  passcode: PropTypes.string,
  currentUser: PropTypes.object.isRequired,
};

export default NewAccountButton;
