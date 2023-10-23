import React from 'react';
import PropTypes from 'prop-types';
import { Route, Routes } from 'react-router-dom';
import TrainingModuleHandler from './training_module_handler.jsx';
import TrainingSlideHandler from './training_slide_handler.jsx';
import TrainingLibrary from './training_library.jsx';

const TrainingApp = () => (
  <div>
    <Routes>
      <Route path=":library_id" element={<TrainingLibrary />} />
      <Route path=":library_id/:module_id" element={<TrainingModuleHandler />} />
      <Route path=":library_id/:module_id/:slide_id" element={<TrainingSlideHandler />} />
    </Routes>
  </div>
);

TrainingApp.propTypes = {
  children: PropTypes.node
};

export default TrainingApp;
