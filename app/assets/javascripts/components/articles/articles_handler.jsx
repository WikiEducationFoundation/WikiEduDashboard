import React from 'react';
import ArticleList from './article_list.jsx';
import UIActions from '../../actions/ui_actions.js';
import AssignmentList from '../assignments/assignment_list.cjsx';
import ServerActions from '../../actions/server_actions.js';

const ArticlesHandler = React.createClass({
  displayName: 'ArticlesHandler',

  propTypes: {
    course_id: React.PropTypes.string
  },

  componentWillMount() {
    ServerActions.fetch('articles', this.props.course_id);
    return ServerActions.fetch('assignments', this.props.course_id);
  },

  sortSelect(e) {
    return UIActions.sort('articles', e.target.value);
  },

  render() {
    return (
      <div>
        <div id="assignments">
          <div className="section-header">
            <h3>{I18n.t('articles.assigned')}</h3>
          </div>
          <AssignmentList {...this.props} />
        </div>

        <div id="articles">
          <div className="section-header">
            <h3>{I18n.t('metrics.articles_edited')}</h3>
            <div className="sort-select">
              <select className="sorts" name="sorts" onChange={this.sortSelect}>
                <option value="rating_num">{I18n.t('articles.rating')}</option>
                <option value="title">{I18n.t('articles.title')}</option>
                <option value="character_sum">{I18n.t('metrics.char_added')}</option>
                <option value="view_count">{I18n.t('metrics.view')}</option>
              </select>
            </div>
          </div>
          <ArticleList {...this.props} />
        </div>
      </div>
    );
  }
});

export default ArticlesHandler;
