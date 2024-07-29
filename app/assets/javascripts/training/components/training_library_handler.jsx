import React, { useState } from 'react';
import Notifications from '../../components/common/notifications.jsx';
import CreateCategory from './modals/create_category.jsx';

const TrainingLibraryHandler = () => {
  const [showModal, setShowModal] = useState(false);

  const toggleModal = () => {
    setShowModal(!showModal);
  };

  return (
    <div className="training-modification">
      <Notifications />
      <div className="container lib-container">
        {showModal && <CreateCategory toggleModal={toggleModal} />}
        <button className="button dark cat-create" onClick={toggleModal}>
          {I18n.t('training.create_category')}
          <i className="icon icon-plus" />
        </button>
      </div>
    </div>

  );
};

export default TrainingLibraryHandler;
