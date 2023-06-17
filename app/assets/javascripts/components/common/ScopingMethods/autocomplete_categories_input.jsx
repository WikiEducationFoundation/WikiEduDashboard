import { debounce } from 'lodash';
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import AsyncSelect from 'react-select/async';
import API from '../../../utils/api';

const CategoryAutoCompleteInput = ({ label, actionType, initial }) => {
  const dispatch = useDispatch();
  const home_wiki = useSelector(state => state.course.home_wiki);

  const search = async (query) => {
    const data = await API.getCategoriesWithPrefix(home_wiki, query);
    return data;
  };

  const _loadOptions = (query, callback) => {
    search(query).then(resp => callback(resp));
  };
  const loadOptions = debounce(_loadOptions, 300);

  const updateCategories = (categories) => {
    dispatch({
      type: actionType,
      categories,
    });
  };

  return (
    <>
      <label htmlFor="categories">{label} </label>
      <AsyncSelect
        loadOptions={loadOptions}
        placeholder={I18n.t('courses_generic.creator.scoping_methods.start_typing_to_search')}
        isMulti
        id="categories"
        onChange={updateCategories}
        noOptionsMessage={() => 'No categories found'}
        defaultValue={initial}
      />
    </>
  );
};

export default CategoryAutoCompleteInput;
