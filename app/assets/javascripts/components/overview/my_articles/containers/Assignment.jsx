import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import MyArticlesHeader from '@components/overview/my_articles/components/Categories/List/Assignment/Header/Header.jsx';
import MyArticlesCompletedAssignment from '@components/overview/my_articles/components/Categories/List/Assignment/CompletedAssignment.jsx';
import MyArticlesProgressTracker from '@components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/ProgressTracker.jsx';

// Main Component
export const Assignment = (props) => {
  const { assignment, course, wikidataLabels } = props;
  const isAssignmentComplete = () => {
    const allStatuses = assignment.assignment_all_statuses;
    const lastStatus = allStatuses[allStatuses.length - 1];
    return assignment.assignment_status === lastStatus;
  };

  const {
    article, title
  } = CourseUtils.articleAndArticleTitle(assignment, course, wikidataLabels);

  const isClassroomProgram = course.type === 'ClassroomProgramCourse';
  const enable = isClassroomProgram && Features.wikiEd;
  const isComplete = isAssignmentComplete();
  const articlesProps = { ...props, article, articleTitle: title, isComplete };
  const progressTracker = isComplete
    ? <MyArticlesCompletedAssignment />
    : <MyArticlesProgressTracker {...articlesProps} />;

  return (
    <div className={`my-assignment mb1${(isComplete && enable) ? ' complete' : ''}`}>
      <MyArticlesHeader {...articlesProps} />
      {enable ? progressTracker : null}
    </div>
  );
};

Assignment.propTypes = {
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  username: PropTypes.string,
  wikidataLabels: PropTypes.object.isRequired,
};

export default (Assignment);
