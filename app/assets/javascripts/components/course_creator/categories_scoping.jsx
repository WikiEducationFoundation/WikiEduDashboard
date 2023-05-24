import React from 'react';
import AsyncSelect from 'react-select/async';
import { useSelector, useDispatch } from 'react-redux';
import { debounce } from 'lodash';
import API from '../../utils/api';
import TextInput from '../common/text_input';
import {
  UPDATE_CATEGORIES,
  UPDATE_CATEGORY_DEPTH,
} from '../../constants/scoping_methods';

const CategoriesScoping = () => {
  const home_wiki = useSelector(state => state.course.home_wiki);
  const depth = useSelector(state => state.scopingMethods.categories.depth);
  const dispatch = useDispatch();

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
    <div className="scoping-methods-categories">
      <div className="form-group">
        <label htmlFor="categories">Categories to track: </label>
        <AsyncSelect
          loadOptions={loadOptions}
          placeholder="Start typing to search"
          isMulti
          id="categories"
          onChange={updateCategories}
          noOptionsMessage={() => 'No categories found'}
        />
      </div>
      <TextInput
        type="number"
        id="category_depth"
        label={I18n.t('categories.depth')}
        placeholder={I18n.t('categories.depth')}
        _value={depth}
        editable
        onChange={(_, value) => {
          if (!value || value > 3 || value.length > 1) {
            return;
          }
          dispatch({
            type: UPDATE_CATEGORY_DEPTH,
            depth: value,
          });
        }}
        max="3"
      />
    </div>
  );
};

export default CategoriesScoping;
