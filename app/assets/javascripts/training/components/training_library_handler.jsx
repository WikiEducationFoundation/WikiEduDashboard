import React, { useState, useEffect } from 'react';
import TrainingNavbar from './navbar_training.jsx';

const TrainingLibraryHandler = ({ navBreadcrumbHandler }) => {
  const [navBreadcrumb, setNavBreadcrumb] = useState(null);
  useEffect(() => {
    navBreadcrumbHandler(setNavBreadcrumb);
  }, []);

  return (
    <div className="training__show">
      <TrainingNavbar navBreadcrumb={navBreadcrumb}/>
    </div>
  );
};

export default TrainingLibraryHandler;
