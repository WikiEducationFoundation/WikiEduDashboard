import { debounce } from 'lodash';
import React, { useRef, useMemo } from 'react';
import { useDispatch } from 'react-redux';
import AsyncSelect from 'react-select/async';
import API from '../../../utils/api';

const TemplatesAutoCompleteInput = ({ label, actionType, initial, wiki }) => {
  const dispatch = useDispatch();

  const searchRef = useRef();
  searchRef.current = query => API.getTemplatesWithPrefix(wiki, query);

  const loadOptions = useMemo(
    () => debounce((query, callback) => {
      searchRef.current(query).then(resp => callback(resp));
    }, 300),
    []
  );

  const updateTemplates = (templates) => {
    dispatch({
      type: actionType,
      templates,
    });
  };

  return (
    <div style={{
      display: 'grid',
      gap: '0.5em',
    }}
    >
      <label htmlFor="templates">{label}</label>
      <AsyncSelect
        loadOptions={loadOptions}
        placeholder={I18n.t('courses_generic.creator.scoping_methods.start_typing_to_search')}
        isMulti
        id="templates"
        onChange={updateTemplates}
        noOptionsMessage={() => 'No Templates found'}
        value={initial}
      />
    </div>
  );
};

export default TemplatesAutoCompleteInput;
