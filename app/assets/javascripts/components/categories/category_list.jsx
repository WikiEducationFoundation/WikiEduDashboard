import React from 'react';
import PropTypes from 'prop-types';

import Category from './category';
import AddCategoryButton from './add_category_button';
import List from '../common/list.jsx';
import moment from 'moment';

const CategoryList = ({ course, editable, categories, loading, removeCategory, addCategory }) => {
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
  };

  const elements = categories.map((cat) => {
    const remove = () => { removeCategory(course.id, cat.id); };
    return <Category key={cat.id} course={course} category={cat} remove={remove} editable={editable} />;
  });

  const category = categories[0];
  let lastUpdate;
  if (category) {
    lastUpdate = category.updated_at;
  }
  const lastUpdateMoment = moment.utc(lastUpdate);
  let lastUpdateMessage;
  if (lastUpdate) {
    lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastUpdateMoment.fromNow()}`;
  }

  let addCategoryButton;
  let addTemplateButton;
  let addPSIDButton;
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
          {addTemplateButton}
        </div>
        <div className="pull-right">
          <div className="tooltip-trigger">
            <small className="mb2">{lastUpdateMessage}</small>
            <div className="tooltip dark" id="petScan-psid">
              <p>{I18n.t('categories.articles_fetch_description')}</p>
            </div>
          </div>
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
  removeCategory: PropTypes.func,
  addCategory: PropTypes.func
};

export default CategoryList;
