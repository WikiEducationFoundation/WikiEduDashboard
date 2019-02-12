import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as ArticleActions from '../../actions/article_actions';
import List from '../common/list.jsx';
import Article from './article.jsx';
import CourseUtils from '../../utils/course_utils.js';

const ArticleList = createReactClass({
  displayName: 'ArticleList',

  propTypes: {
    articles: PropTypes.array,
    course: PropTypes.object,
    current_user: PropTypes.object,
    actions: PropTypes.object,
    articleDetails: PropTypes.object,
    sortBy: PropTypes.func,
    wikidataLabels: PropTypes.object,
    sort: PropTypes.object
  },

  getInitialState() {
    return {
      selectedIndex: -1,
    };
  },

  shouldShowDiff(index) {
    return this.state.selectedIndex === index;
  },

  isFirstArticle(index) {
    return index === 0;
  },

  isLastArticle(index) {
    return index === (this.props.articles.length - 1);
  },

  showPreviousArticle(index) {
    this.setState({
      selectedIndex: index - 1
    });
  },

  showNextArticle(index) {
    this.setState({
      selectedIndex: index + 1
    });
  },

  showDiff(index) {
    this.setState({
      selectedIndex: index
    });
  },

  hideDiff() {
    this.setState({
      selectedIndex: -1
    });
  },

  render() {
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

    const sort = this.props.sort;
    if (sort.key) {
      const order = (sort.sortKey) ? 'asc' : 'desc';
      keys[sort.key].order = order;
    }

    // If a parameter like ?showArticle=123 is present,
    // the ArticleViewer should go into show mode immediately.
    // this allows for links to directly view a specific article.
    const showArticleId = Number(location.search.split('showArticle=')[1]);
    const articleElements = this.props.articles.map((article, index) => (
      <Article
        article={article}
        index={index}
        showOnMount={showArticleId === article.id}
        course={this.props.course}
        key={article.id}
        wikidataLabel={this.props.wikidataLabels[article.title]}
        // eslint-disable-next-line
        current_user={this.props.current_user}
        fetchArticleDetails={this.props.actions.fetchArticleDetails}
        articleDetails={this.props.articleDetails[article.id] || null}
        shouldShowDiff={this.shouldShowDiff}
        showDiff={this.showDiff}
        hideDiff={this.hideDiff}
        isFirstArticle={this.isFirstArticle}
        isLastArticle={this.isLastArticle}
        showPreviousArticle={this.showPreviousArticle}
        showNextArticle={this.showNextArticle}
      />
    ));

    return (
      <List
        elements={articleElements}
        keys={keys}
        sortable={true}
        table_key="articles"
        className="table--expandable table--hoverable"
        none_message={CourseUtils.i18n('articles_none', this.props.course.string_prefix)}
        sortBy={this.props.sortBy}
      />
    );
  }
});

const mapStateToProps = state => ({
  articleDetails: state.articleDetails,
  sort: state.articles.sort,
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});


export default connect(mapStateToProps, mapDispatchToProps)(ArticleList);
