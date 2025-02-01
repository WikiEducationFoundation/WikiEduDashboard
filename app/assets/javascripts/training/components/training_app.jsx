import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { Route, Routes } from 'react-router-dom';

import TrainingContentHandler from './training_content_handler.jsx';
import TrainingLibraryHandler from './training_library_handler.jsx';
import TrainingModuleHandler from './training_module_handler.jsx';
import TrainingSlideHandler from './training_slide_handler.jsx';
import { getCurrentUser } from '../../selectors/index.js';
import { getTrainingMode } from '../../actions/training_modification_actions.js';
import AddModule from './modals/add_module.jsx';

const TrainingApp = () => {
  const dispatch = useDispatch();
  const editMode = useSelector(state => state.training.editMode);
  const currentUser = useSelector(state => getCurrentUser(state));

  useEffect(() => {
    dispatch(getTrainingMode());
  }, []);

  return (
    <div>
      <Routes>
        <Route path="/" element={<TrainingContentHandler editMode={editMode} currentUser={currentUser}/>}/>
        <Route path=":library_id" element={<TrainingLibraryHandler editMode={editMode}/>}/>
        <Route path=":library_id/:module_id" element={<TrainingModuleHandler editMode={editMode}/>} />
        <Route path=":library_id/:module_id/:slide_id" element={<TrainingSlideHandler />} />
        <Route path=":library_id/edit/:category_id/add_module" element={<AddModule editMode={editMode} />} />
      </Routes>
    </div>
  );
};

TrainingApp.propTypes = {
  children: PropTypes.node
};

export default TrainingApp;
