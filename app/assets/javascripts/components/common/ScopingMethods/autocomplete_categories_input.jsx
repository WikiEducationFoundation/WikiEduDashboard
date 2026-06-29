import { debounce } from 'lodash';
import React, { useRef, useMemo } from 'react';
import { useDispatch } from 'react-redux';
import AsyncSelect from 'react-select/async';
import API from '../../../utils/api';

const CategoryAutoCompleteInput = ({ label, actionType, initial, wiki, depth }) => {
  const dispatch = useDispatch();

  const searchRef = useRef();
  searchRef.current = query => API.getCategoriesWithPrefix(wiki, query, depth);

  const loadOptions = useMemo(
    () => debounce((query, callback) => {
      searchRef.current(query).then(resp => callback(resp));
    }, 300),
    []
  );

  const updateCategories = (categories) => {
    dispatch({
      type: actionType,
      categories: categories.map(item => ({
        value: item.value,
        label: item.value.label,
      })),
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
        value={initial}
      />
    </>
  );
};

export default CategoryAutoCompleteInput;
