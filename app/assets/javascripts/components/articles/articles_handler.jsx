import React from 'react';
import ArticleList from './article_list.jsx';
import UIActions from '../../actions/ui_actions.js';
import AssignmentList from '../assignments/assignment_list.jsx';
import ServerActions from '../../actions/server_actions.js';
import AvailableArticles from '../articles/available_articles.jsx';

const ArticlesHandler = React.createClass({
  displayName: 'ArticlesHandler',

  propTypes: {
    course_id: React.PropTypes.string,
    current_user: React.PropTypes.object
  },

  componentWillMount() {
    ServerActions.fetch('articles', this.props.course_id);
    ServerActions.fetch('assignments', this.props.course_id);
  },

  sortSelect(e) {
    return UIActions.sort('articles', e.target.value);
  },

  render() {
    let header;
    if (Features.wikiEd) {
      header = <h3 className="tooltip-trigger">{I18n.t('metrics.articles_edited')}</h3>;
    } else {
      header = (
        <h3 className="tooltip-trigger">{I18n.t('metrics.articles_edited')}
          <span className="tooltip-indicator"></span>
          <div className="tooltip dark">
            <p>{I18n.t('articles.cross_wiki_tracking')}</p>
          </div>
        </h3>
      );
    }

    return (
      <div>
        <div id="articles">
          <div className="section-header">
            {header}
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
        <div id="assignments" className="mt4">
          <div className="section-header">
            <h3>{I18n.t('articles.assigned')}</h3>
          </div>
          <AssignmentList {...this.props} />
        </div>
        <AvailableArticles {...this.props} />
      </div>
    );
  }
});

export default ArticlesHandler;
