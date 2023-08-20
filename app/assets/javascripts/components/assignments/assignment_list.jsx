import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { sortBy, groupBy, compact } from 'lodash-es';

import List from '../common/list.jsx';
import Assignment from './assignment.jsx';
import { getFiltered } from '../../utils/model_utils.js';
import ArticleUtils from '../../utils/article_utils.js';

const AssignmentList = ({ course, assignments, articles, current_user, wikidataLabels, }) => {
  useEffect(() => {
    // sets the title of this tab
    const project = course.home_wiki.project;
    document.title = `${course.title} - ${ArticleUtils.I18n('assigned', project)}`;
  }, []);

  const hasAssignedUser = (group) => {
    return group.some((assignment) => {
      return assignment.user_id;
    });
  };

  const sortedAssignments = sortBy(assignments, assignment => assignment.article_title);
  const grouped = groupBy(sortedAssignments, assignment => assignment.article_title);
  let elements = Object.keys(grouped).map((title) => {
    const group = grouped[title];
    if (!hasAssignedUser(group)) { return null; }
    const article = getFiltered(articles, { title })[0];
    return (
      <Assignment
        key={group[0].id}
        assignmentGroup={group}
        article={article || null}
        course={course}
        current_user={current_user}
        wikidataLabel={wikidataLabels[title]}
      />
    );
  });
  elements = compact(elements);

  const keys = {
    rating_num: {
      label: I18n.t('articles.rating'),
      desktop_only: true
    },
    title: {
      label: I18n.t('articles.title'),
      desktop_only: false
    },
    assignee: {
      label: I18n.t('assignments.assignees'),
      desktop_only: true
    },
    reviewer: {
      label: I18n.t('assignments.reviewers'),
      desktop_only: true
    }
  };

  const project = course.home_wiki.project;

  return (
    <div id="assignments" className="mt4">
      <div className="section-header">
        <h3>{ArticleUtils.I18n('assigned', project)}</h3>
      </div>
      <List
        elements={elements}
        keys={keys}
        table_key={'assignments'}
        none_message={ArticleUtils.I18n('assignments_none', project)}
        sortable={false}
      />
    </div>
  );
};

AssignmentList.propTypes = {
  articles: PropTypes.array,
  assignments: PropTypes.array,
  course: PropTypes.object,
  current_user: PropTypes.object,
  wikidataLabels: PropTypes.object
};

export default AssignmentList;
