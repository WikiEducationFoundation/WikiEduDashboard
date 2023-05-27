import React from 'react';
import CategoryAutoCompleteInput from '../../common/ScopingMethods/autocomplete_categories_input';
import { UPDATE_EXCLUDE_CATEGORIES_PETSCAN, UPDATE_EXCLUDE_TEMPLATES_PETSCAN, UPDATE_INCLUDE_CATEGORIES_PETSCAN, UPDATE_INCLUDE_TEMPLATES_PETSCAN } from '../../../constants/scoping_methods';
import TemplatesAutoCompleteInput from '../../common/ScopingMethods/autocomplete_templates_input';
import { useSelector } from 'react-redux';

const PetScanQueryBuilder = () => {
  const templatesIncluded = useSelector(state => state.scopingMethods.petscan.templates_includes);
  const templatesExcluded = useSelector(state => state.scopingMethods.petscan.templates_excludes);
  const categoriesIncluded = useSelector(state => state.scopingMethods.petscan.categories_includes);
  const categoriesExcluded = useSelector(state => state.scopingMethods.petscan.categories_excludes);

  return (
    <div className="scoping-method-petscan-builder">
      <div className="form-group">
        <CategoryAutoCompleteInput label="Categories to include:" actionType={UPDATE_INCLUDE_CATEGORIES_PETSCAN} initial={categoriesIncluded}/>
      </div>
      <div className="form-group">
        <CategoryAutoCompleteInput label="Categories to exclude:" actionType={UPDATE_EXCLUDE_CATEGORIES_PETSCAN} initial={categoriesExcluded}/>
      </div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to include:" actionType={UPDATE_INCLUDE_TEMPLATES_PETSCAN} initial={templatesIncluded}/>
      </div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to exclude:" actionType={UPDATE_EXCLUDE_TEMPLATES_PETSCAN} initial={templatesExcluded}/>
      </div>
    </div>
  );
};

export default PetScanQueryBuilder;
