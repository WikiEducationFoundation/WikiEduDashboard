import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import List from '../common/list.jsx';
import Assignment from './assignment.jsx';
import CourseUtils from '../../utils/course_utils.js';
import { getFiltered } from '../../utils/model_utils.js';

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
    const sortedAssignments = _.sortBy(allAssignments, ass => ass.article_title);
    const grouped = _.groupBy(sortedAssignments, ass => ass.article_title);
    let elements = Object.keys(grouped).map((title) => {
      const group = grouped[title];
      if (!this.hasAssignedUser(group)) { return null; }
      const article = getFiltered(this.props.articles, { title })[0];
      return (
        <Assignment
          assignmentGroup={group}
          article={article || null}
          wikidataLabel={this.props.wikidataLabels[title]}
          course={this.props.course}
          key={group[0].id}
          current_user={this.props.current_user}
        />
      );
    });
    elements = _.compact(elements);

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

    return (
      <List
        elements={elements}
        keys={keys}
        table_key={'assignments'}
        none_message={CourseUtils.i18n('assignments_none', this.props.course.string_prefix)}
        sortable={false}
      />
    );
  }
}
);

export default AssignmentList;
