import React from 'react';
import PropTypes from 'prop-types';

// Components
import EditedUnassignedArticleRow from './EditedUnassignedArticleRow';
import List from '@components/common/list.jsx';

export const EditedUnassignedArticles = ({
  articles, course, current_user, showArticleId, title, user,
  fetchArticleDetails
}) => {
  const rows = articles.map(article => (
    <EditedUnassignedArticleRow
      key={`article-${article.id}`}
      article={article}
      course={course}
      current_user={current_user}
      fetchArticleDetails={fetchArticleDetails}
      showArticleId={showArticleId}
      user={user}
    />
  ));

  const options = { desktop_only: false, sortable: false };
  const keys = {
    article_name: {
      label: I18n.t('instructor_view.assignments_table.article_name'),
      ...options
    },
    relevant_links: {
      label: I18n.t('instructor_view.assignments_table.relevant_links'),
      ...options
    }
  };

  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">{title}</h4>
      <List
        elements={rows}
        className="table--expandable table--hoverable"
        keys={keys}
        table_key="users"
        stickyHeader={false}
        sortable={false}
      />
    </div>
  );
};

EditedUnassignedArticles.propTypes = {
  articles: PropTypes.arrayOf(PropTypes.object).isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  showArticleId: PropTypes.any,
  title: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired,
  fetchArticleDetails: PropTypes.func.isRequired
};

export default EditedUnassignedArticles;
