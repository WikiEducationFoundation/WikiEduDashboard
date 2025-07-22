import React from 'react';
import PropTypes from 'prop-types';

import Category from './category';
import AddCategoryButton from './add_category_button';
import List from '../common/list.jsx';
import { removeCategory } from '@actions/category_actions.js';

import { useDispatch } from 'react-redux';

const CategoryList = ({ course, editable, categories, loading, addCategory }) => {
  const keys = {
    category_name: {
      label: I18n.t('categories.name')
    },
    depth: {
      label: I18n.t('categories.depth')
    },
    articles_count: {
      label: I18n.t('categories.articles_count')
    },
    timestamp: {
      label: I18n.t('categories.timestamp'),
      info_key: 'categories.import_articles_description'
    },
  };

  const dispatch = useDispatch();

  const elements = categories.map((cat) => {
    const remove = () => { dispatch(removeCategory(course.id, cat.id)); };
    return <Category key={cat.id} course={course} category={cat} remove={remove} editable={editable} />;
  });

  let addCategoryButton;
  let addTemplateButton;
  let addPSIDButton;
  let addPileIDButton;
  if (editable) {
    addCategoryButton = (
      <AddCategoryButton
        key="add_category_button"
        addCategory={addCategory}
        course={course}
        source="category"
      />
    );
    addPSIDButton = (
      <AddCategoryButton
        key="add_psid_button"
        addCategory={addCategory}
        course={course}
        source="psid"
      />
    );
    addPileIDButton = (
      <AddCategoryButton
        key="add_pileid_button"
        addCategory={addCategory}
        course={course}
        source="pileid"
      />
    );
    addTemplateButton = (
      <AddCategoryButton
        key="add_template_button"
        addCategory={addCategory}
        course={course}
        source="template"
      />
    );
  }

  return (
    <div id="category-list" className="mt4">
      <div className="section-header">
        <h3>{I18n.t('categories.tracked_categories')}</h3>
        <div className="section-header__actions">
          {addCategoryButton}
          {addPSIDButton}
          {addPileIDButton}
          {addTemplateButton}
        </div>
      </div>
      <List
        elements={elements}
        keys={keys}
        table_key="categories"
        none_message={I18n.t('categories.none')}
        loading={loading}
      />
    </div>
  );
};

CategoryList.propTypes = {
  course: PropTypes.object,
  categories: PropTypes.array,
  addCategory: PropTypes.func
};

export default CategoryList;
