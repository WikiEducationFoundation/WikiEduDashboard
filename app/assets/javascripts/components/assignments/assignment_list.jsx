import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import Editable from '../high_order/editable.jsx';
import List from '../common/list.jsx';
import Assignment from './assignment.jsx';
import AssignmentStore from '../../stores/assignment_store.js';
import ArticleStore from '../../stores/article_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const getState = () => ({ assignments: AssignmentStore.getModels() });

const AssignmentList = createReactClass({
  displayName: 'AssignmentList',

  propTypes: {
    assignments: PropTypes.array,
    course: PropTypes.object,
    current_user: PropTypes.object
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
    let elements = Object.keys(grouped).map(title => {
      const group = grouped[title];
      if (!this.hasAssignedUser(group)) { return null; }
      const article = ArticleStore.getFiltered({ title })[0];
      return (
        <Assignment
          assignmentGroup={group}
          article={article || null}
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
        store={AssignmentStore}
        sortable={false}
      />
    );
  }
}
);

export default Editable(AssignmentList, [ArticleStore, AssignmentStore], ServerActions.saveStudents, getState);
