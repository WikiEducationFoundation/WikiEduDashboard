import React from 'react';
import CourseUtils from '../../utils/course_utils';

const Category = ({ course, category, remove, editable }) => {
  let removeButton;
  if (editable) {
    removeButton = <button className="button pull-right small danger" onClick={remove}>{I18n.t('categories.remove')}</button>;
  }

  const catName = CourseUtils.formattedCategoryName(category, course.home_wiki);
  let depth;
  if (category.source === 'category') {
    depth = category.depth;
  }

  return (
    <tr>
      <td>{catName}</td>
      <td>{depth}</td>
      <td>{category.articles_count}</td>
      <td>{removeButton}</td>
    </tr>
  );
};

export default Category;
