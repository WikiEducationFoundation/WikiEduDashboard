import React from 'react';
import PropTypes from 'prop-types';

// Components
import CurrentStatus from './CurrentStatus';
import AssignmentLinks from '@components/common/AssignmentLinks/AssignmentLinks.jsx';
import ArticleViewer from '@components/common/article_viewer.jsx';

export const Assignment = ({ assignment, course, fetchArticleDetails, user }) => {
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
  return (
    <tr className="article-row">
      <td className="article-title">{assignment.article_title}</td>
      <td>
        <AssignmentLinks
          assignment={assignment}
          courseType={course.type}
          user={user}
        />
      </td>
      <td className="current-status">
        <CurrentStatus
          current={assignment.assignment_status}
          statuses={assignment.assignment_all_statuses}
        />
      </td>
      <td>
        <ArticleViewer
          article={article}
          fetchArticleDetails={fetchArticleDetails}
          showPermalink={false}
          users={users}
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
    assignment_status: PropTypes.string.isRequired
  }).isRequired,
  course: PropTypes.shape({
    type: PropTypes.string.isRequired
  }).isRequired,
  user: PropTypes.object.isRequired
};

export default Assignment;
