import React, { useState } from 'react';
import CourseUtils from '../../utils/course_utils';
import { toDate } from '../../utils/date_utils';
import { isSameDay, formatDistanceToNow } from 'date-fns';
import ArticleTitlesModal from './article_titles_modal';
import { createPortal } from 'react-dom';

const Category = ({ course, category, remove, editable }) => {
  let removeButton;
  if (editable) {
    removeButton = (
      <button className="button pull-right small danger" onClick={remove}>
        {I18n.t('categories.remove')}
      </button>
    );
  }
  const [showModal, setShowModal] = useState(false);

  const catName = CourseUtils.formattedCategoryName(category, course.home_wiki);
  let depth;
  let link;
  if (category.source === 'category') {
    depth = category.depth;
  }
  if (category.source === 'psid') {
    link = `https://petscan.wmcloud.org/?psid=${category.name}`;
  } else if (category.source === 'pileid') {
    link = `https://pagepile.toolforge.org/api.php?id=${category.name}&action=get_data`;
  } else {
    link = `https://${course.home_wiki.language}.${course.home_wiki.project}.org/wiki/${catName}`;
  }
  const lastUpdate = toDate(category.updated_at);
  let lastUpdateMessage;
  const beenUpdated = !isSameDay(toDate(category.created_at), lastUpdate);
  if (lastUpdate) {
    lastUpdateMessage = !beenUpdated
      ? '---'
      : `${I18n.t('metrics.last_update')}: ${formatDistanceToNow(lastUpdate, {
          addSuffix: true,
        })}`;
  }
  return (
    <>
      <tr>
        <td>
          <a target="_blank" href={link}>
            {catName}
          </a>
        </td>
        <td>{depth}</td>
        <td>
          <div
            style={{
              display: 'flex',
              gap: '5px',
              alignItems: 'end',
            }}
          >
            <p
              style={{
                margin: 0,
              }}
            >
              {category.articles_count}
            </p>
            {beenUpdated && (
              <small>
                <button onClick={() => setShowModal(true)}>
                  {I18n.t('articles.view_articles')}
                </button>
              </small>
            )}
          </div>
        </td>
        <td>
          <div className="pull-center">
            <small className="mb2">{lastUpdateMessage}</small>
          </div>
        </td>
        <td>{removeButton}</td>
      </tr>
      {showModal && (
        // this would work without a portal as well, but it would be rendered inside the table
        // which causes react to complain about invalid html
        createPortal(
          <ArticleTitlesModal
            setShowModal={setShowModal}
            category={category}
            course={course}
            lastUpdateMessage={`${I18n.t(
            'metrics.last_articles_update'
          )}: ${formatDistanceToNow(lastUpdate, { addSuffix: true })}`}
          />, document.body)
      )}
    </>
  );
};

export default Category;
