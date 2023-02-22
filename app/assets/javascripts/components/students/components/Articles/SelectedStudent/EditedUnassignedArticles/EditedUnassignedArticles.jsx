import React from 'react';
import PropTypes from 'prop-types';
import * as ArticleActions from '../../../../../../actions/articles_actions';
import { bindActionCreators } from 'redux';

// Components
import EditedUnassignedArticleRow from './EditedUnassignedArticleRow';
import List from '@components/common/list.jsx';
import { connect } from 'react-redux';
import withRouter from '../../../../../util/withRouter.jsx';

const EditedUnassignedArticles = ({
  articles, course, current_user, showArticleId, title, user,
  fetchArticleDetails, ...props
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


  const showMore = () => {
    return props.actions.fetchArticles(course.slug, props.limit + 500);
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
      <div className="see-more">
        {!props.limitReached
          && (
            <button
              style={{ width: 'max-content', height: 'max-content', marginTop: '20px' }}
              className="button ghost articles-see-more-btn " onClick={showMore}
            >
              {I18n.t('articles.see_more')}
            </button>
          )
        }
      </div>
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

const mapStateToProps = (state) => {
  return ({
    limit: state.articles.limit,
    limitReached: state.articles.limitReached,
  });
};

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});


export default withRouter(connect(mapStateToProps, mapDispatchToProps)(EditedUnassignedArticles));


