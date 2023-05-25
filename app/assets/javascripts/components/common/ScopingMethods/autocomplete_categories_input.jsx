import { debounce } from 'lodash';
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import AsyncSelect from 'react-select/async';
import API from '../../../utils/api';
import { UPDATE_CATEGORIES } from '../../../constants/scoping_methods';

const CategoryAutoCompleteInput = () => {
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
      type: UPDATE_CATEGORIES,
      categories,
    });
  };

  return (
    <>
      <label htmlFor="categories">Categories to track: </label>
      <AsyncSelect
        loadOptions={loadOptions}
        placeholder="Start typing to search"
        isMulti
        id="categories"
        onChange={updateCategories}
        noOptionsMessage={() => 'No categories found'}
      />
    </>
  );
};

export default CategoryAutoCompleteInput;
