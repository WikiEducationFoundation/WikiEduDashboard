import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { useSelector } from 'react-redux';
import TrainingModuleHandler from './training_module_handler.jsx';
import TrainingSlideHandler from './training_slide_handler.jsx';
import TrainingLibrary from './training_library.jsx';
import Affix from '../../components/common/affix.jsx';
import TrainingNavbar from './training_navbar.jsx';


const TrainingApp = () => {
  const course = useSelector(state => state.course);
  const currentUser = useSelector(state => state);
  return (
    <div>
      <div className="course-nav__wrapper">
        <Affix className="course_navigation" offset={57}>
          <TrainingNavbar
            course={course}
            currentUser={currentUser}
          />
        </Affix>
      </div>
      <Routes>
        <Route path=":library_id/:module_id" element={<TrainingModuleHandler />} />
        <Route path=":library_id" element={<TrainingLibrary />} />
        <Route path=":library_id/:module_id/:slide_id" element={<TrainingSlideHandler />} />
      </Routes>
    </div>
  );
};

export default TrainingApp;

