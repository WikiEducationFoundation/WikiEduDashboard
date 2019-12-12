import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import MyArticlesHeader from '@components/overview/my_articles/components/Categories/List/Assignment/Header/Header.jsx';
import MyArticlesCompletedAssignment from '@components/overview/my_articles/components/Categories/List/Assignment/CompletedAssignment.jsx';
import MyArticlesProgressTracker from '@components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/ProgressTracker.jsx';

import { initiateConfirm } from '~/app/assets/javascripts/actions/confirm_actions';
import { deleteAssignment, fetchAssignments, updateAssignmentStatus } from '~/app/assets/javascripts/actions/assignment_actions';

// Main Component
export class Assignment extends React.Component {
  isComplete() {
    const { assignment } = this.props;
    const allStatuses = assignment.assignment_all_statuses;
    const lastStatus = allStatuses[allStatuses.length - 1];
    return assignment.assignment_status === lastStatus;
  }

  render() {
    const { assignment, course, wikidataLabels, editable } = this.props;

    const {
      article, title
    } = CourseUtils.articleAndArticleTitle(assignment, course, wikidataLabels, editable);

    const isComplete = this.isComplete();
    const isClassroomProgram = course.type === 'ClassroomProgramCourse';
    const enable = isClassroomProgram && Features.enableAdvancedFeatures; // TODO: Remove when ready

    const props = { ...this.props, article, articleTitle: title, isComplete };
    const progressTracker = isComplete
      ? <MyArticlesCompletedAssignment />
      : <MyArticlesProgressTracker {...props} />;

    return (
      <div className={`my-assignment mb1${(isComplete && enable) ? ' complete' : ''}`}>
        <MyArticlesHeader {...props} editable={editable} />
        { enable ? progressTracker : null }
      </div>
    );
  }
}

Assignment.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  username: PropTypes.string,
  wikidataLabels: PropTypes.object.isRequired,
  editable: PropTypes.bool,
  // actions
  deleteAssignment: PropTypes.func.isRequired,
  fetchAssignments: PropTypes.func.isRequired,
  initiateConfirm: PropTypes.func.isRequired,
  updateAssignmentStatus: PropTypes.func.isRequired
};

const mapDispatchToProps = {
  initiateConfirm,
  deleteAssignment,
  fetchAssignments,
  updateAssignmentStatus
};

export default connect(null, mapDispatchToProps)(Assignment);
