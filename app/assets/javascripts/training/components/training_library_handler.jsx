import React, { useState, useEffect } from 'react';
import TrainingNavbar from './navbar_training.jsx';

const TrainingLibraryHandler = () => {
  const [navBreadcrumb, setNavBreadcrumb] = useState(null);
  useEffect(() => {
    setNavBreadcrumb(document.getElementById('react_root').getAttribute('data-breadcrumbs'));
  }, []);

  return (
    <div className="training__show">
      <TrainingNavbar navBreadcrumb={navBreadcrumb}/>
    </div>
  );
};

export default TrainingLibraryHandler;
