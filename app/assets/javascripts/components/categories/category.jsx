import React from 'react';
import CourseUtils from '../../utils/course_utils';
import moment from 'moment';

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
  const lastUpdate = category.updated_at;
  const lastUpdateMoment = moment.utc(lastUpdate);
  let lastUpdateMessage;
  if (lastUpdate) {
    lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastUpdateMoment.fromNow()}`;
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
