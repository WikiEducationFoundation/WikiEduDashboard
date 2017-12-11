import React from 'react';
import Category from './category';
import AddCategoryButton from './add_category_button';
import List from '../common/list.jsx';

const CategoryList = ({ course, editable, categories, loading, removeCategory, addCategory }) => {
  const keys = {
    category_name: {
      label: I18n.t('categories.name')
    },
    depth: {
      label: I18n.t('categories.depth')
    },
  };

  const elements = categories.map((cat) => {
    const remove = () => { removeCategory(course.id, cat.id); };
    return <Category key={cat.id} course={course} category={cat} remove={remove} editable={editable} />;
  });

  let addCategoryButton;
  let addTemplateButton;
  if (editable) {
    addCategoryButton = (
      <AddCategoryButton
        key="add_category_button"
        addCategory={addCategory}
        course={course}
        source="category"
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
  course: React.PropTypes.object,
  categories: React.PropTypes.array,
  removeCategory: React.PropTypes.func,
  addCategory: React.PropTypes.func
};

export default CategoryList;
