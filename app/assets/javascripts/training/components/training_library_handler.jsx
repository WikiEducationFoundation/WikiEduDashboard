import React, { useState } from 'react';
import { useSelector } from 'react-redux';
import CreateLibrary from './modals/create_library';
import Notifications from '../../components/common/notifications.jsx';
import { getCurrentUser } from '../../selectors';

const TrainingLibraryHandler = () => {
  const [showModal, setShowModal] = useState(false);
  const currentUser = useSelector(state => getCurrentUser(state));

  const modalHandler = () => {
    setShowModal(!showModal);
  };

  return (
    <div className="container lib-container">
      <Notifications className="lib-notifications" />
      {showModal && <CreateLibrary modalHandler={modalHandler} />}
      {currentUser.isAdmin && (
        <button className="button dark lib-create" onClick={modalHandler}>
          {I18n.t('training.create_library')}
          <i className="icon icon-plus" />
        </button>
      )}
    </div>
  );
};

export default TrainingLibraryHandler;
