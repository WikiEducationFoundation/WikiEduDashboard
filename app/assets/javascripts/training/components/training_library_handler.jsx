import React, { useState } from 'react';
import Notifications from '../../components/common/notifications.jsx';
import CreateCategory from './modals/create_category.jsx';
import TransferModules from './modals/transfer_modules.jsx';

const TrainingLibraryHandler = (props) => {
  const [showCreateCategoryForm, setShowCreateCategoryForm] = useState(false);
  const [transferModulesForm, setTransferModulesForm] = useState(false);

  const toggleCreateCategoryModal = () => {
    setShowCreateCategoryForm(!showCreateCategoryForm);
  };

  const toggleTransferModulesModal = () => {
    setTransferModulesForm(!transferModulesForm);
  };

  if (!props.editMode) {
    return null;
  }

  return (
    <div className="training-modification">
      <Notifications />
      <div className="container lib-container">
        {showCreateCategoryForm && <CreateCategory toggleModal={toggleCreateCategoryModal} />}
        {transferModulesForm && <TransferModules toggleModal={toggleTransferModulesModal} />}
        <div className="library-page-btn-container">
          <button className="button dark" onClick={toggleCreateCategoryModal}>
            {I18n.t('training.create_category')}
            <i className="icon icon-plus" />
          </button>
          <button className="button dark" onClick={toggleTransferModulesModal}>
            {I18n.t('training.transfer_module')}
          </button>
        </div>
      </div>
    </div>

  );
};

export default TrainingLibraryHandler;
