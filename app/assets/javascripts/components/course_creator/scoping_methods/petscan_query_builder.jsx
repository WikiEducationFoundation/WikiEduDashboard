import React from 'react';
import CategoryAutoCompleteInput from '../../common/ScopingMethods/autocomplete_categories_input';
import { UPDATE_EXCLUDE_CATEGORIES_PETSCAN, UPDATE_EXCLUDE_TEMPLATES_PETSCAN, UPDATE_INCLUDE_CATEGORIES_PETSCAN, UPDATE_INCLUDE_TEMPLATES_PETSCAN, UPDATE_NAMESPACES as UPDATE_NAMESPACES_PETSCAN } from '../../../constants/scoping_methods';
import TemplatesAutoCompleteInput from '../../common/ScopingMethods/autocomplete_templates_input';
import { useSelector } from 'react-redux';
import AutocompleteNamespacesInput from '../../common/ScopingMethods/autocomplete_namespaces_input';

const PetScanQueryBuilder = () => {
  const templatesIncluded = useSelector(state => state.scopingMethods.petscan.templates_includes);
  const templatesExcluded = useSelector(state => state.scopingMethods.petscan.templates_excludes);
  const categoriesIncluded = useSelector(state => state.scopingMethods.petscan.categories_includes);
  const categoriesExcluded = useSelector(state => state.scopingMethods.petscan.categories_excludes);
  const namespacesIncluded = useSelector(state => state.scopingMethods.petscan.namespaces);

  return (
    <div className="scoping-method-petscan-builder">
      <div className="form-group">
        <CategoryAutoCompleteInput
          label={
            <div className="tooltip-trigger">
              <label htmlFor="categories">Categories To Include</label>
              <span className="tooltip-indicator"/>
              <div className="tooltip dark">
                {I18n.t('courses_generic.creator.scoping_methods.categories_include_AND')}
              </div>
            </div>
        } actionType={UPDATE_INCLUDE_CATEGORIES_PETSCAN} initial={categoriesIncluded}
        />
      </div>
      <div className="form-group">
        <CategoryAutoCompleteInput label="Categories to exclude:" actionType={UPDATE_EXCLUDE_CATEGORIES_PETSCAN} initial={categoriesExcluded}/>
      </div>
      <div className="form-group">
        <TemplatesAutoCompleteInput
          label={
            <div className="tooltip-trigger">
              <label htmlFor="templates">Templates To Include</label>
              <span className="tooltip-indicator"/>
              <div className="tooltip dark">
                {I18n.t('courses_generic.creator.scoping_methods.templates_include_AND')}
              </div>
            </div>
        } actionType={UPDATE_INCLUDE_TEMPLATES_PETSCAN} initial={templatesIncluded}
        />
      </div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to exclude:" actionType={UPDATE_EXCLUDE_TEMPLATES_PETSCAN} initial={templatesExcluded}/>
      </div>
      <div
        className="form-group" style={{
        gridColumn: '1 / -1',
      }}
      >
        <AutocompleteNamespacesInput label="Namespaces to Include:" actionType={UPDATE_NAMESPACES_PETSCAN} initial={namespacesIncluded}/>
      </div>
    </div>
  );
};

export default PetScanQueryBuilder;
