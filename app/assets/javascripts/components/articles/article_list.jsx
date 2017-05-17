import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as UIActions from '../../actions';
import Editable from '../high_order/editable.jsx';
import List from '../common/list.jsx';
import Article from './article.jsx';
import ArticleDrawer from './article_drawer.jsx';
import ArticleStore from '../../stores/article_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';


const getState = () => {
  return {
    articles: ArticleStore.getModels()
  };
};

const ArticleList = React.createClass({
  displayName: 'ArticleList',

  propTypes: {
    articles: React.PropTypes.array,
    course: React.PropTypes.object,
    current_user: React.PropTypes.object,
    openKey: React.PropTypes.string,
    actions: React.PropTypes.object
  },

  render() {
    const toggleDrawer = this.props.actions.toggleUI;
    const articles = this.props.articles.map(article => {
      const drawerKey = `drawer_${article.id}`;
      const isOpen = this.props.openKey === drawerKey;
      return (
        <Article
          article={article}
          course={this.props.course}
          toggleDrawer={toggleDrawer}
          key={article.id}
          isOpen={isOpen}
        />
      );
    });

    const articleDrawers = this.props.articles.map(article => {
      const key = `drawer_${article.id}`;
      const isOpen = this.props.openKey === key;
      return (
        <ArticleDrawer
          article={article}
          course={this.props.course}
          key={key}
          isOpen={isOpen}
          current_user={this.props.current_user}
        />
      );
    });

    const elements = _.flatten(_.zip(articles, articleDrawers));

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
      }
    };

    return (
      <List
        elements={elements}
        keys={keys}
        sortable={true}
        table_key="articles"
        className="table--expandable table--hoverable"
        none_message={CourseUtils.i18n('articles_none', this.props.course.string_prefix)}
        store={ArticleStore}
      />
    );
  }
});

const mapStateToProps = state => ({
  openKey: state.ui.openKey
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators(UIActions, dispatch)
});

export default Editable(
  connect(mapStateToProps, mapDispatchToProps)(ArticleList),
  [ArticleStore], ServerActions.saveArticles, getState
);
