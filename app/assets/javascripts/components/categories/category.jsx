import React from 'react';
import CourseUtils from '../../utils/course_utils';

const Category = ({ course, category, remove, editable }) => {
  let removeButton;
  if (editable) {
    removeButton = <button className="button pull-right small danger" onClick={remove}>{I18n.t('categories.remove')}</button>;
  }

  const catName = CourseUtils.formattedCategoryName(category, course.home_wiki);

  return (
    <tr>
      <td>{catName}</td>
      <td>{category.depth}</td>
      <td>{removeButton}</td>
    </tr>
  );
};

export default Category;
