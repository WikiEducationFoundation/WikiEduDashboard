import React from 'react';
import AsyncSelect from 'react-select/async';
import API from '../../../utils/api';
import { useDispatch, useSelector } from 'react-redux';
import { debounce } from 'lodash';
import { UPDATE_TEMPLATES } from '../../../constants/scoping_methods';

const TemplatesScoping = () => {
  const home_wiki = useSelector(state => state.course.home_wiki);
  const dispatch = useDispatch();

  const search = async (query) => {
    const data = await API.getTemplatesWithPrefix(home_wiki, query);
    return data;
  };

  const _loadOptions = (query, callback) => {
    search(query).then(resp => callback(resp));
  };

  const loadOptions = debounce(_loadOptions, 300);

  const updateTemplates = (templates) => {
    dispatch({
      type: UPDATE_TEMPLATES,
      templates,
    });
  };

  return (
    <div>
      <div className="form-group">
        <label htmlFor="templates">Templates to include: </label>
        <AsyncSelect
          loadOptions={loadOptions}
          placeholder="Start typing to search"
          isMulti
          id="templates"
          onChange={updateTemplates}
          noOptionsMessage={() => 'No Templates found'}
        />
      </div>
    </div>
  );
};

export default TemplatesScoping;
