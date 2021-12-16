import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { sortBy, groupBy, compact } from 'lodash-es';

import List from '../common/list.jsx';
import Assignment from './assignment.jsx';
import { getFiltered } from '../../utils/model_utils.js';
import ArticlesOrItemseUtils from '../../utils/articles_or_items_utils.js';

const AssignmentList = createReactClass({
  displayName: 'AssignmentList',

  propTypes: {
    articles: PropTypes.array,
    assignments: PropTypes.array,
    course: PropTypes.object,
    current_user: PropTypes.object,
    wikidataLabels: PropTypes.object
  },

  hasAssignedUser(group) {
    return group.some((assignment) => {
      return assignment.user_id;
    });
  },

  render() {
    const allAssignments = this.props.assignments;
    const sortedAssignments = sortBy(allAssignments, assignment => assignment.article_title);
    const grouped = groupBy(sortedAssignments, assignment => assignment.article_title);
    let elements = Object.keys(grouped).map((title) => {
      const group = grouped[title];
      if (!this.hasAssignedUser(group)) { return null; }
      const article = getFiltered(this.props.articles, { title })[0];
      return (
        <Assignment
          key={group[0].id}
          assignmentGroup={group}
          article={article || null}
          course={this.props.course}
          current_user={this.props.current_user}
          wikidataLabel={this.props.wikidataLabels[title]}
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

    const articlesOrItems = ArticlesOrItemseUtils.articlesOrItems(this.props.course.home_wiki.project);

    return (
      <div id="assignments" className="mt4">
        <div className="section-header">
          <h3>{ArticlesOrItemseUtils.articlesOrItemsI18n('assigned', articlesOrItems)}</h3>
        </div>
        <List
          elements={elements}
          keys={keys}
          table_key={'assignments'}
          none_message={ArticlesOrItemseUtils.articlesOrItemsI18n('assignments_none', articlesOrItems)}
          sortable={false}
        />
      </div>
    );
  }
}
);

export default AssignmentList;
