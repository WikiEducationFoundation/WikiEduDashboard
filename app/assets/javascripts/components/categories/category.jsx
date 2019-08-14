import React from 'react';
import CourseUtils from '../../utils/course_utils';

const Category = ({ course, category, remove, editable }) => {
  let removeButton;
  if (editable) {
    removeButton = <button className="button pull-right small danger" onClick={remove}>{I18n.t('categories.remove')}</button>;
  }

  const catName = CourseUtils.formattedCategoryName(category, course.home_wiki);
  let depth;
  let link;
  if (category.source === 'category') {
    depth = category.depth;
  }
  if (category.source === 'psid') {
    link = `https://petscan.wmflabs.org/?psid=${category.name}`;
  } else {
    link = `https://en.wikipedia.org/wiki/${catName}`;
  }

  return (
    <tr>
      <td>
        <a href={link}>{catName}</a>
      </td>
      <td>{depth}</td>
      <td>{category.articles_count}</td>
      <td>{removeButton}</td>
    </tr>
  );
};

export default Category;
