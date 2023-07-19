import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import TextInput from '../../common/text_input';
import {
  UPDATE_CATEGORIES,
  UPDATE_CATEGORY_DEPTH
} from '../../../constants/scoping_methods';
import CategoryAutoCompleteInput from '../../common/ScopingMethods/autocomplete_categories_input';
import WikiSelect from '../../common/wiki_select';

const CategoriesScoping = () => {
  const depth = useSelector(state => state.scopingMethods.categories.depth);
  const categories = useSelector(state => state.scopingMethods.categories.tracked);
  const home_wiki = useSelector(state => state.course.home_wiki);
  const dispatch = useDispatch();
  const [currentWiki, setCurrentWiki] = useState(home_wiki);
  return (
    <div
      className={'scoping-methods-categories'}
    >
      <div className="form-group">
        <CategoryAutoCompleteInput
          label={
            <div className="tooltip-trigger">
              <label htmlFor="categories">Categories To Include</label>
              <span className="tooltip-indicator"/>
              <div className="tooltip dark">
                {I18n.t('courses_generic.creator.scoping_methods.categories_include_OR')}
              </div>
            </div>
        } actionType={UPDATE_CATEGORIES} initial={categories}
          wiki={currentWiki}
          home_wiki = {home_wiki}
        />
      </div>
      <div className="scoping-methods-categories-bottom-wrapper">
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
        <WikiSelect homeWiki={home_wiki} onChange={wiki => setCurrentWiki(wiki.value)}/>
      </div>
    </div>
  );
};

export default CategoriesScoping;
