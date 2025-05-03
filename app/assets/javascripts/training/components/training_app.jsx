import React from 'react';
import PropTypes from 'prop-types';
import { Route, Routes } from 'react-router-dom';

import TrainingModuleHandler from './training_module_handler.jsx';
import TrainingSlideHandler from './training_slide_handler.jsx';
import TrainingLibraryHandler from './training_library_handler.jsx';

const TrainingApp = () => {
  const navBreadcrumbHandler = (setNavBreadcrumb) => {
    setNavBreadcrumb(document.getElementById('react_root').getAttribute('data-breadcrumbs'));
  };
  return (
    <div>
      <Routes>
        <Route path=":library_id" element={<TrainingLibraryHandler navBreadcrumbHandler={navBreadcrumbHandler}/>} />
        <Route path=":library_id/:module_id" element={<TrainingModuleHandler navBreadcrumbHandler={navBreadcrumbHandler}/>} />
        <Route path=":library_id/:module_id/:slide_id" element={<TrainingSlideHandler navBreadcrumbHandler={navBreadcrumbHandler}/>} />
      </Routes>
    </div>
  );
};

TrainingApp.propTypes = {
 children: PropTypes.node
};

export default TrainingApp;
