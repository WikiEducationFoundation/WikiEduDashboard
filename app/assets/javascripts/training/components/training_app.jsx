import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Route, Routes } from 'react-router-dom';

import TrainingModuleHandler from './training_module_handler.jsx';
import TrainingSlideHandler from './training_slide_handler.jsx';
import TrainingLibraryHandler from './training_library_handler.jsx';
import TrainingHandler from './training_handler.jsx';

const TrainingApp = () => {
  const [courseId, setCourseId] = useState(null);

  useEffect(() => {
  }, [courseId]);

  return (
    <div>
      <Routes>
        <Route path="course/:course_id" element={<TrainingHandler setCourseId={setCourseId} />} />
        <Route path=":library_id" element={<TrainingLibraryHandler />} />
        <Route path=":library_id/:module_id" element={<TrainingModuleHandler />} />
        <Route path=":library_id/:module_id/:slide_id" element={<TrainingSlideHandler courseId={courseId} />} />
      </Routes>
    </div>
  );
};

TrainingApp.propTypes = {
  children: PropTypes.node
};

export default TrainingApp;
