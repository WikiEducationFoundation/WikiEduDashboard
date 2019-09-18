import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import CourseUtils from '../../../../utils/course_utils.js';
import MyArticlesHeader from '../components/Categories/List/Assignment/Header';
import MyArticlesProgressTracker from '../components/Categories/List/Assignment/ProgressTracker';

import { initiateConfirm } from '../../../../actions/confirm_actions';
import { deleteAssignment, fetchAssignments, updateAssignmentStatus } from '../../../../actions/assignment_actions';

// Main Component
export const MyAssignment = createReactClass({
  displayName: 'MyAssignment',

  propTypes: {
    assignment: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    course: PropTypes.object.isRequired,
    username: PropTypes.string,
    wikidataLabels: PropTypes.object.isRequired
  },

  isComplete() {
    const { assignment } = this.props;
    const allStatuses = assignment.assignment_all_statuses;
    const lastStatus = allStatuses[allStatuses.length - 1];
    return assignment.assignment_status === lastStatus;
  },

  render() {
    const { assignment, course, current_user, username, wikidataLabels } = this.props;

    const article = CourseUtils.articleFromTitleInput(assignment.article_url);
    const label = wikidataLabels[article.title.replace('www:wikidata', '')];
    let articleTitle = assignment.article_title;
    articleTitle = CourseUtils.formattedArticleTitle(article, course.home_wiki, label);

    const isComplete = this.isComplete();
    const props = {
      article,
      articleTitle,
      assignment,
      course,
      current_user,
      isComplete,
      username,
      deleteAssignment: this.props.deleteAssignment,
      fetchAssignments: this.props.fetchAssignments,
      initiateConfirm: this.props.initiateConfirm,
      updateAssignmentStatus: this.props.updateAssignmentStatus
    };

    return (
      <div className={`my-assignment mb1${isComplete ? ' complete' : ''}`}>
        <MyArticlesHeader {...props} />
        {
          isComplete
            ? <section className="completed-assignment">{'You\'ve marked your article as complete.'}</section>
            : <MyArticlesProgressTracker {...props} />
        }
      </div>
    );
  }
});

const mapDispatchToProps = {
  initiateConfirm,
  deleteAssignment,
  fetchAssignments,
  updateAssignmentStatus
};

export default connect(null, mapDispatchToProps)(MyAssignment);
