import React, { useState } from 'react';
import { ScopingMethod } from './scoping_method';
import ScopingMethodTypes from './scoping_method_types';
import CategoriesScoping from './scoping_methods/categories_scoping';
import { useSelector } from 'react-redux';
import { getLongDescription, getScopingMethodLabel } from '@components/util/scoping_methods';
import { CATEGORIES, PETSCAN, TEMPLATES } from '../../constants/scoping_methods';
import TemplatesScoping from './scoping_methods/templates_scoping';
import PetScanScoping from './scoping_methods/petscan_scoping';

const CourseScoping = ({ show, wizardController, showCourseDates }) => {
  const selectedScopingMethods = useSelector(state => state.scopingMethods.selected);
  const scopingMethods = [
    'index',
    ...selectedScopingMethods
  ];

  const [pageNumber, setPageNumber] = useState(0);
  const [descriptionHidden, setDescriptionHidden] = useState(false);

  const canGoPrev = pageNumber > 0;
  const pageName = scopingMethods[pageNumber];
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

  const hideDescription = (hidden) => {
    setDescriptionHidden(hidden);
  };

  return (
    <div className={`wizard__scoping ${show ? '' : 'hidden'}`}>
      <ScopingMethod
        index={pageNumber}
        nextPage={nextPage}
        prevPage={prevPage}
        description={!descriptionHidden && getLongDescription(scopingMethods[pageNumber])}
        name={getScopingMethodLabel(scopingMethods[pageNumber])}
        canGoNext={canGoNext}
        canGoPrev={canGoPrev}
        wizardController={wizardController}
      >
        {pageName === 'index' && <ScopingMethodTypes />}
        {pageName === CATEGORIES && <CategoriesScoping />}
        {pageName === TEMPLATES && <TemplatesScoping />}
        {pageName === PETSCAN && <PetScanScoping hideDescription={hideDescription}/>}
      </ScopingMethod>
    </div>
  );
};

export default CourseScoping;
