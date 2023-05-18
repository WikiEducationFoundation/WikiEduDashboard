import React, { useState } from 'react';
import { ScopingMethod } from './scoping_method';
import ScopingMethodTypes from './scoping_method_types';
import CategoriesScoping from './categories_scoping';

const scopingMethods = [
  'Scoping Methods',
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

  const getDescription = () => {
    if (pageNumber === 0) {
      return I18n.t('courses_generic.creator.scoping_methods.about');
    }
    if (pageNumber === 1) {
      return I18n.t('courses_generic.creator.scoping_methods.categories_desc');
    }
    return '';
  };

  return (
    <div className={`wizard__scoping ${show ? '' : 'hidden'}`}>
      <ScopingMethod
        index={pageNumber}
        nextPage={nextPage}
        prevPage={prevPage}
        description={getDescription()}
        name={scopingMethods[pageNumber]}
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
