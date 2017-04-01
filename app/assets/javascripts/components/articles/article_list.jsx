import React from 'react';
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
    current_user: React.PropTypes.object
  },

  render() {
    const articles = this.props.articles.map(article => {
      return <Article article={article} key={article.id} {...this.props} />;
    });

    const articleDrawers = this.props.articles.map(article => {
      return (
        <ArticleDrawer
          article={article}
          course={this.props.course}
          key={`${article.id}_drawer`}
          ref={`${article.id}_drawer`}
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

export default Editable(ArticleList, [ArticleStore], ServerActions.saveArticles, getState);
