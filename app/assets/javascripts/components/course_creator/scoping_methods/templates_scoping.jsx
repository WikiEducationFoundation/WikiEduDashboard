import React from 'react';
import TemplatesAutoCompleteInput from '../../common/ScopingMethods/autocomplete_templates_input';
import { UPDATE_TEMPLATES } from '../../../constants/scoping_methods';
import { useSelector } from 'react-redux';

const TemplatesScoping = () => {
  const templates = useSelector(state => state.scopingMethods.templates.include);
  return (
    <div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to include:" actionType={UPDATE_TEMPLATES} initial={templates}/>
      </div>
    </div>
  );
};

export default TemplatesScoping;
