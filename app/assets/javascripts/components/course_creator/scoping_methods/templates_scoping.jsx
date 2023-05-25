import React from 'react';
import TemplatesAutoCompleteInput from '../../common/ScopingMethods/autocomplete_templates_input';
import { UPDATE_TEMPLATES } from '../../../constants/scoping_methods';

const TemplatesScoping = () => {
  return (
    <div>
      <div className="form-group">
        <TemplatesAutoCompleteInput label="Templates to include:" actionType={UPDATE_TEMPLATES}/>
      </div>
    </div>
  );
};

export default TemplatesScoping;
