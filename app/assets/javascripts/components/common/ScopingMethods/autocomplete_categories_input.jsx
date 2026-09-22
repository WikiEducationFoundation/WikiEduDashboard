import { debounce } from 'lodash';
import React, { useRef, useMemo } from 'react';
import { useDispatch } from 'react-redux';
import AsyncSelect from 'react-select/async';
import API from '../../../utils/api';
import { UPDATE_TRACKED_CATEGORY_DEPTH } from '../../../constants/scoping_methods';

const DEPTH_OPTIONS = [0, 1, 2, 3];

const CategoryAutoCompleteInput = ({ label, actionType, initial, wiki, defaultDepth }) => {
  const dispatch = useDispatch();

  const searchRef = useRef();
  searchRef.current = query => API.getCategoriesWithPrefix(wiki, query, defaultDepth);

  const loadOptions = useMemo(
    () => debounce((query, callback) => {
      searchRef.current(query).then(resp => callback(resp));
    }, 300),
    []
  );

  const updateCategories = (categories) => {
    dispatch({
      type: actionType,
      categories,
    });
  };

  const updateDepth = (index, depth) => {
    dispatch({
      type: UPDATE_TRACKED_CATEGORY_DEPTH,
      index,
      depth,
    });
  };

  const removeCategory = (index) => {
    updateCategories(initial.filter((_, i) => i !== index));
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
        // Selections are listed below instead of as chips, so that each one
        // can carry its own depth control.
        controlShouldRenderValue={false}
      />
      {initial.length > 0 && (
        <ul className="selected-categories">
          {initial.map((category, index) => (
            <li className="selected-category" key={category.label}>
              <span className="selected-category__name">{category.label}</span>
              <label
                className="selected-category__depth-label"
                htmlFor={`category_depth_${index}`}
              >
                {I18n.t('categories.depth')}
              </label>
              <select
                id={`category_depth_${index}`}
                className="selected-category__depth"
                value={category.value.depth ?? 0}
                onChange={e => updateDepth(index, Number(e.target.value))}
              >
                {DEPTH_OPTIONS.map(depth => (
                  <option key={depth} value={depth}>{depth}</option>
                ))}
              </select>
              <button
                type="button"
                className="selected-category__remove"
                aria-label={`${I18n.t('categories.remove')} ${category.label}`}
                onClick={() => removeCategory(index)}
              >
                ×
              </button>
            </li>
          ))}
        </ul>
      )}
    </>
  );
};

export default CategoryAutoCompleteInput;
