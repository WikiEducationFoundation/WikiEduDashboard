import React from 'react';
import CourseUtils from '../../utils/course_utils';
import { toDate } from '../../utils/date_utils';
import { isSameDay, formatDistanceToNow } from 'date-fns';

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
  } else if (category.source === 'pileid') {
    link = `https://pagepile.toolforge.org/api.php?id=${category.name}&action=get_data`;
  } else {
    link = `https://${course.home_wiki.language}.${course.home_wiki.project}.org/wiki/${catName}`;
  }
  const lastUpdate = toDate(category.updated_at);
  let lastUpdateMessage;
  if (lastUpdate) {
    lastUpdateMessage = isSameDay(toDate(category.created_at), lastUpdate)
      ? '---'
      : `${I18n.t('metrics.last_update')}: ${formatDistanceToNow(lastUpdate)}`;
  }

  return (
    <tr>
      <td>
        <a target="_blank" href={link}>{catName}</a>
      </td>
      <td>{depth}</td>
      <td>{category.articles_count}</td>
      <td>
        <div className="pull-center">
          <small className="mb2">{lastUpdateMessage}</small>
        </div>
      </td>
      <td>{removeButton}</td>
    </tr>
  );
};

export default Category;
