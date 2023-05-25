import React from 'react';
import CategoryAutoCompleteInput from '../../common/ScopingMethods/autocomplete_categories_input';
import { UPDATE_EXCLUDE_CATEGORIES_PETSCAN, UPDATE_EXCLUDE_TEMPLATES_PETSCAN, UPDATE_INCLUDE_CATEGORIES_PETSCAN, UPDATE_INCLUDE_TEMPLATES_PETSCAN } from '../../../constants/scoping_methods';
import TemplatesAutoCompleteInput from '../../common/ScopingMethods/autocomplete_templates_input';

const PetScanQueryBuilder = () => {
  return (
    <div className="scoping-method-petscan-builder">
      <div className="form-group">
        <CategoryAutoCompleteInput label="Categories to include:" actionType={UPDATE_INCLUDE_CATEGORIES_PETSCAN}/>
      </div>
      <div className="form-group">
        <CategoryAutoCompleteInput label="Categories to exclude:" actionType={UPDATE_EXCLUDE_CATEGORIES_PETSCAN}/>
      </div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to include:" actionType={UPDATE_INCLUDE_TEMPLATES_PETSCAN}/>
      </div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to exclude:" actionType={UPDATE_EXCLUDE_TEMPLATES_PETSCAN}/>
      </div>
    </div>
  );
};

export default PetScanQueryBuilder;
