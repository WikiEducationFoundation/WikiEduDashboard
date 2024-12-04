import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import CreateLibrary from './modals/create_library.jsx';
import Notifications from '../../components/common/notifications.jsx';
import { updateTrainingMode } from '../../actions/training_modification_actions.js';

const TrainingContentHandler = (props) => {
  const [showModal, setShowModal] = useState(false);
  const [updatingEditMode, setUpdatingEditMode] = useState(false);
  const dispatch = useDispatch();
  const { usersignedin: userSignedInStr } = document.getElementById('nav_root').dataset;
  const userSignedIn = userSignedInStr === 'true';

  const toggleModal = () => {
    setShowModal(!showModal);
  };

  const toggleEditMode = () => {
    setUpdatingEditMode(true);
    dispatch(updateTrainingMode(!props.editMode, setUpdatingEditMode));
  };

  let trainingMode;
  if (props.editMode) {
    trainingMode = I18n.t('training.switch_view');
  } else {
    trainingMode = I18n.t('training.switch_edit');
  }

  let buttonStyle;
  if (updatingEditMode) {
    buttonStyle = { pointerEvents: 'none', opacity: '0.5' };
  }

  return (
    <div className="training-modification">
      <Notifications />
      <div className="container lib-container ">
        {showModal && <CreateLibrary toggleModal={toggleModal} />}
        <div className="training_content_page_btn_container">
          {props.editMode && props.currentUser.isAdmin && (
            <button className="button dark" onClick={toggleModal}>
              {I18n.t('training.create_library')}
              <i className="icon icon-plus" />
            </button>
          )}
          {/* Switching to edit mode is only allowed for admins */}
          {userSignedIn && props.currentUser.isAdmin && (
            <button className="button dark" onClick={toggleEditMode} style={buttonStyle}>
              {trainingMode}
            </button>
          )}
        </div>
      </div>
    </div>

  );
};

export default TrainingContentHandler;
