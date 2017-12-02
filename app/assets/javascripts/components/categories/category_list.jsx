import React from 'react';
import Category from './category';

const CategoryList = ({ course, categories, loading, removeCategory }) => {
  let headers;
  const elements = categories.map((cat) => {
    const remove = () => { removeCategory(course.id, cat.id); };
    return <Category key={cat.id} category={cat} remove={remove} />;
  });

  const table = (
    <table className="categories_table table">
      <thead>
        <tr>
          {headers}
          <th />
        </tr>
      </thead>
      <tbody>
        {elements}
      </tbody>
    </table>
  );

  return (
    <div id="category-list" className="mt4">
      <div className="section-header">
        <h3>{I18n.t('categories.category_list')}</h3>
        <div className="section-header__actions">
          Actions go here
        </div>
      </div>
      {table}
    </div>
  );
};

CategoryList.propTypes = {
  course: React.PropTypes.object,
  categories: React.PropTypes.array,
  remove: React.PropTypes.func
};

export default CategoryList;
