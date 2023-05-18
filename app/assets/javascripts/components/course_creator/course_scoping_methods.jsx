import React, { useState } from 'react';
import { ScopingMethod } from './scoping_method';
import ScopingMethodTypes from './scoping_method_types';
import CategoriesScoping from './categories_scoping';
import { useSelector } from 'react-redux';
import { getLongDescription, getScopingMethodLabel } from '@components/util/scoping_methods';

const CourseScoping = ({ show, wizardController, showCourseDates }) => {
  const selectedScopingMethods = useSelector(state => state.scopingMethods.selected);
  const scopingMethods = [
    'index',
    ...selectedScopingMethods
  ];

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
        description={getLongDescription(scopingMethods[pageNumber])}
        name={getScopingMethodLabel(scopingMethods[pageNumber])}
        canGoNext={canGoNext}
        canGoPrev={canGoPrev}
        wizardController={wizardController}
      >
        {pageNumber === 0 && <ScopingMethodTypes />}
        {pageNumber === 1 && <CategoriesScoping />}
      </ScopingMethod>
    </div>
  );
};

export default CourseScoping;
