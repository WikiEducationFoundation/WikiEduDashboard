import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as ArticleActions from '../../actions/article_actions';
import List from '../common/list.jsx';
import Article from './article.jsx';
import CourseUtils from '../../utils/course_utils.js';

const ArticleList = ({
  articles,
  course,
  current_user,
  actions,
  articleDetails,
  sortBy,
  wikidataLabels,
  sort
}) => {
  const keys = {
    rating_num: {
      label: I18n.t('articles.rating'),
      desktop_only: true,
      info_key: 'articles.rating_doc'
    },
    title: {
      label: I18n.t('articles.title'),
      desktop_only: false
    },
    character_sum: {
      label: I18n.t('metrics.char_added'),
      desktop_only: true,
      info_key: 'articles.character_doc'
    },
    view_count: {
      label: I18n.t('metrics.view'),
      desktop_only: true,
      info_key: 'articles.view_doc'
    },
    tools: {
      label: I18n.t('articles.tools'),
      desktop_only: false,
      sortable: false
    }
  };
  if (sort.key) {
    const order = (sort.sortKey) ? 'asc' : 'desc';
    keys[sort.key].order = order;
  }
  // If a parameter like ?showArticle=123 is present,
  // the ArticleViewer should go into show mode immediately.
  // this allows for links to directly view a specific article.
  const showArticleId = Number(location.search.split('showArticle=')[1]);
  const articleElements = articles.map(article => (
    <Article
      article={article}
      showOnMount={showArticleId === article.id}
      course={course}
      key={article.id}
      wikidataLabel={wikidataLabels[article.title]}
      // eslint-disable-next-line
      current_user={current_user}
      fetchArticleDetails={actions.fetchArticleDetails}
      articleDetails={articleDetails[article.id] || null}
    />
  ));

  return (
    <List
      elements={articleElements}
      keys={keys}
      sortable={true}
      table_key="articles"
      className="table--expandable table--hoverable"
      none_message={CourseUtils.i18n('articles_none', course.string_prefix)}
      sortBy={sortBy}
    />
  );
};

ArticleList.propTypes = {
  articles: PropTypes.array,
  course: PropTypes.object,
  current_user: PropTypes.object,
  actions: PropTypes.object,
  articleDetails: PropTypes.object
};

const mapStateToProps = state => ({
  articleDetails: state.articleDetails,
  sort: state.articles.sort,
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});


export default connect(mapStateToProps, mapDispatchToProps)(ArticleList);
