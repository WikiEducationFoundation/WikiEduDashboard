import React, { useState } from 'react';
import { ScopingMethod } from './scoping_method';

const scopingMethods = [
  'Categories',
  'Templates',
  'PagePile',
  'PetScan'
];

const CourseScoping = ({ show, wizardController, showCourseDates }) => {
  const [pageNumber, setPageNumber] = useState(0);
  const canGoPrev = pageNumber > 0;
  const canGoNext = pageNumber < scopingMethods.length - 1;

  const nextPage = (i) => {
    if (canGoNext) {
      setPageNumber(i + 1);
    }
  };
  const prevPage = (i) => {
    // if it is possible to go back to the previous scoping method, do so
    if (canGoPrev) {
      setPageNumber(i - 1);
    } else {
      // otherwise, go back to the course dates
      showCourseDates();
    }
  };

  return (
    <div className={`wizard__scoping ${show ? '' : 'hidden'}`}>
      <ScopingMethod
        index={pageNumber}
        nextPage={nextPage}
        prevPage={prevPage}
        description={'none'}
        name={scopingMethods[pageNumber]}
        canGoNext={canGoNext}
        canGoPrev={canGoPrev}
        wizardController={wizardController}
      />
    </div>
  );
};

export default CourseScoping;
