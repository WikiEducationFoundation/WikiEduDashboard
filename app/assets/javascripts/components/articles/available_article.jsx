import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { initiateConfirm } from '@actions/confirm_actions';

import CourseUtils from '../../utils/course_utils.js';
import API from '../../utils/api.js';
import { deleteAssignment, claimAssignment } from '../../actions/assignment_actions.js';

export const AvailableArticle = ({ assignment, current_user, course, selectable }) => {
  const dispatch = useDispatch();

  const onSelectHandler = async () => {
    const assignmentObj = {
      id: assignment.id,
      user_id: current_user.id,
      role: 0
    };

    const title = assignment.article_title;

    const successNotification = {
      message: I18n.t('assignments.article', { title }),
      closable: true,
      type: 'success'
    };
    // Check if article title is under a particular wikipedia category
    const isArticleInCategory = (await API.checkArticleInWikiCategory(title))[0] === title;
    const actionToDispatch = isArticleInCategory ? initiateConfirm : claimAssignment;

    const onConfirm = () => dispatch(claimAssignment(assignmentObj, successNotification));
    const confirmMessage = I18n.t('articles.discouraged_article', {
      type: 'Assigning',
      action: 'assign',
      article: 'article',
      article_list: title
    });

    dispatch(actionToDispatch(isArticleInCategory
    ? { confirmMessage: confirmMessage, onConfirm } : assignmentObj, successNotification));
  };

  const onRemoveHandler = (e) => {
    e.preventDefault();

    const assignmentObj = {
      id: assignment.id,
      course_slug: course.slug,
      language: assignment.language,
      project: assignment.project,
      article_title: assignment.article_title,
      role: 0
    };

    if (!confirm(I18n.t('assignments.confirm_deletion'))) { return; }
    return dispatch(deleteAssignment(assignmentObj));
  };

  const className = 'assignment';

  const article = CourseUtils.articleFromAssignment(assignment, course.home_wiki);
  const ratingClass = `rating ${assignment.article_rating}`;
  const ratingMobileClass = `${ratingClass} tablet-only`;
  const articleLink = (
    <a
      onClick={stop}
      href={article.url}
      target="_blank"
      className="inline"
      style={{
        color:
          assignment.article_rating === 'does_not_exist'
            ? '#dd3333'
            : '#3366cc',
      }}
    >
      {article.formatted_title}
    </a>
  );
  const isWikipedia = article.project === 'wikipedia';

  let actionSelect;
  let actionRemove;
  if (current_user.isStudent && selectable) {
    actionSelect = (
      <button className="button dark" onClick={onSelectHandler}>{I18n.t('assignments.select')}</button>
    );
  }

  if (current_user.isAdvancedRole) {
    actionRemove = (
      <button className="button dark" onClick={onRemoveHandler}>{I18n.t('assignments.remove')}</button>
    );
  }

  return (
    <tr className={className}>
      <td className="tooltip-trigger desktop-only-tc">
        {isWikipedia && <p className="rating_num hidden">{article.rating_num}</p>}
        {isWikipedia && <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>}
        {isWikipedia && (
          <div className="tooltip dark">
            <p>
              {I18n.t(`articles.rating_docs.${assignment.article_rating || '?'}`, { class: assignment.article_rating || '' })}
            </p>
          </div>
        )}
      </td>
      <td>
        {isWikipedia && <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>}
        <p className="title">
          {articleLink}
        </p>
      </td>
      <td className="table-action-cell">
        {actionSelect}
        {actionRemove}
      </td>
    </tr>
  );
};

AvailableArticle.propTypes = {
  assignment: PropTypes.object,
  current_user: PropTypes.object,
  course: PropTypes.object,
  selectable: PropTypes.bool
};

export default (AvailableArticle);
