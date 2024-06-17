import React, { useState } from 'react';
import { useSelector } from 'react-redux';
import CreateLibrary from './modals/create_library.jsx';
import Notifications from '../../components/common/notifications.jsx';
import { getCurrentUser } from '../../selectors/index.js';

const TrainingContentHandler = () => {
  const [showModal, setShowModal] = useState(false);
  const currentUser = useSelector(state => getCurrentUser(state));

  const toggleModal = () => {
    setShowModal(!showModal);
  };

  return (
    <div className="training-modification">
      <Notifications />
      <div className="container lib-container ">
        {showModal && <CreateLibrary toggleModal={toggleModal} />}
        {currentUser.isAdmin && (
          <button className="button dark lib-create" onClick={toggleModal}>
            {I18n.t('training.create_library')}
            <i className="icon icon-plus" />
          </button>
        )}
      </div>
    </div>

  );
};

export default TrainingContentHandler;
