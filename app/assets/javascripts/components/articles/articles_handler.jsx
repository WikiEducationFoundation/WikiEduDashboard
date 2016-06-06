import React from 'react';
import ArticleList from './article_list.jsx';
import UIActions from '../../actions/ui_actions.js';
import AssignmentList from '../assignments/assignment_list.cjsx';
import AvailableArticlesList from '../articles/available_article_list.cjsx';
import ServerActions from '../../actions/server_actions.js';
import AssignCell from '../students/assign_cell.cjsx';

const ArticlesHandler = React.createClass({
  displayName: 'ArticlesHandler',

  propTypes: {
    course_id: React.PropTypes.string,
    course: React.PropTypes.object,
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
    let assignCell;

    if (this.props.course.id) {
      assignCell = (
        <AssignCell
          course={this.props.course}
          role={0}
          editable
          add_available={true}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
          assignments={[]}
          prefix={I18n.t('users.my_assigned')}
        />
      );
    }

    return (
      <div>
        <div id="articles" className="mt4">
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
        <div id="assignments" className="mt4">
          <div className="section-header">
            <h3>{I18n.t('articles.assigned')}</h3>
          </div>
          <AssignmentList {...this.props} />
        </div>
        <div id="available-articles" className="mt4">
          <div className="section-header">
            <h3>{I18n.t('articles.available')}</h3>
            <div className="section-header__actions">
              {assignCell}
            </div>
          </div>
          <AvailableArticlesList {...this.props} />
        </div>
      </div>
    );
  }
});

export default ArticlesHandler;
