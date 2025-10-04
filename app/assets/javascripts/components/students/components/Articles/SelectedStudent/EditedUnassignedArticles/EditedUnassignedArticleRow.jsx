import React from 'react';
import PropTypes from 'prop-types';

// Components
import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';

export const EditedUnassignedArticleRow = ({
  article, course, current_user, fetchArticleDetails, showArticleId, user, wikidataLabel
}) => (
  <tr className="article-row">
    <td className="article-title">{wikidataLabel ?? article.title}</td>
    <td>
      <p className="assignment-links">
        <a href={article.url} target="_blank">
          {I18n.t('assignments.article_link')}
        </a>
      </p>
    </td>
    <td className="article-actions">
      <ArticleViewer
        article={article}
        course={course}
        current_user={current_user}
        fetchArticleDetails={fetchArticleDetails}
        users={[user.username]}
        showOnMount={showArticleId === article.id}
      />
    </td>
  </tr>
);

EditedUnassignedArticleRow.propTypes = {
  article: PropTypes.shape({
    id: PropTypes.number.isRequired,
    url: PropTypes.string.isRequired
  }).isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  showArticleId: PropTypes.any,
  user: PropTypes.shape({
    username: PropTypes.string.isRequired
  }).isRequired,
  fetchArticleDetails: PropTypes.func.isRequired
};

export default EditedUnassignedArticleRow;
