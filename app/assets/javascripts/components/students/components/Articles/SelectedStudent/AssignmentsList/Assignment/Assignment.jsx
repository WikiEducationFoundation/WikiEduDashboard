import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

// Components
import CurrentStatus from './CurrentStatus';
import AssignmentLinks from '@components/common/AssignmentLinks/AssignmentLinks.jsx';
import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';

export const Assignment = ({ assignment, course, current_user, fetchArticleDetails, user, articleDetails }) => {
  const article = {
    ...assignment,
    course_id: course.id,
    language: assignment.language || course.home_wiki.language,
    id: assignment.article_id,
    project: assignment.project || course.home_wiki.project,
    title: assignment.article_title,
    url: assignment.article_url
  };
  const users = assignment.editors
    ? assignment.editors.concat(user.username)
    : [user.username];

  const showArticleId = Number(location.search.split('showArticle=')[1]);
  let currentStatus;
  if (course.progress_tracker_enabled) {
    currentStatus = (
      <CurrentStatus
        current={assignment.assignment_status}
        statuses={assignment.assignment_all_statuses}
      />
    );
  }
  const getAllEditors = () => {
    fetchArticleDetails(article.id, course.id);
  };
  const details = articleDetails[article.id] || null;
  return (
    <tr className="article-row">
      <td className="article-title">{assignment.article_title}</td>
      <td>
        <AssignmentLinks
          assignment={assignment}
          courseType={course.type}
          user={user}
          project={course.home_wiki.project}
          course={course}
        />
      </td>
      <td className="current-status">
        {currentStatus}
      </td>
      <td className="article-actions">
        <ArticleViewer
          article={article}
          course={course}
          current_user={current_user}
          fetchArticleDetails={getAllEditors}
          users={details && details.editors}
          assignedUsers={users}
          showOnMount={showArticleId === article.id}
        />
      </td>
    </tr>
  );
};

Assignment.propTypes = {
  assignment: PropTypes.shape({
    article_title: PropTypes.string.isRequired,
    assignment_all_statuses: PropTypes.arrayOf(PropTypes.string).isRequired,
    assignment_status: PropTypes.string
  }).isRequired,
  course: PropTypes.shape({
    type: PropTypes.string.isRequired
  }).isRequired,
  current_user: PropTypes.object.isRequired,
  user: PropTypes.object.isRequired
};

const mapStateToProps = ({ articleDetails }) => ({ articleDetails });
export default connect(mapStateToProps)(Assignment);
