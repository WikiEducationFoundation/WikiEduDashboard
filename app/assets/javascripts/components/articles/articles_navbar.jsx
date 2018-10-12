import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import { Link } from 'react-router';
import _ from 'lodash';
import { updateArticlesCurrent, toggleScrollDebounce } from '../../actions/ui_actions_redux.js';

import Affix from '../common/affix.jsx';

const ArticlesNavbar = createReactClass({
  onNavClick(e) {
    this.props.toggleScrollDebounce();
    return this.props.updateArticlesCurrent(e.target.getAttribute('data-key'));
  },

  render() {
    let availableArticlesNav;
    if (this.props.assignments.length > 0 || this.props.current_user.isNonstudent) {
      availableArticlesNav = (
        <li key="available-articles" className={this.props.articlesUi.articlesCurrent === 'available-articles' ? 'is-current' : ''}>
          <Link to={`/courses/${this.props.course_id}/articles#available-articles`} data-key="available-articles" onClick={this.onNavClick}>
            {I18n.t('articles.available')}
            <div className="articles-count">{_.filter(this.props.assignments, { user_id: null }).length}</div>
          </Link>
        </li>
        );
    }
    return (
      <div className="articles-nav">
        <Affix offset={100}>
          <div className="panel">
            <ol>
              <li key="articles-edited" className={this.props.articlesUi.articlesCurrent === 'articles-edited' ? 'is-current' : ''}>
                <Link to={`/courses/${this.props.course_id}/articles#articles-edited`} data-key="articles-edited" onClick={this.onNavClick}>
                  {I18n.t('metrics.articles_edited')}
                  <div className="articles-count">{this.props.articles.length}</div>
                </Link>
              </li>
              <li key="articles-assigned" className={this.props.articlesUi.articlesCurrent === 'articles-assigned' ? 'is-current' : ''}>
                <Link to={`/courses/${this.props.course_id}/articles#articles-assigned`} data-key="articles-assigned" onClick={this.onNavClick}>
                  {I18n.t('articles.assigned')}
                  <div className="articles-count">{_.filter(this.props.assignments, (obj) => { return obj.user_id != null; }).length}</div>
                </Link>
              </li>
              {availableArticlesNav}
              <li key="article-finder" className={this.props.articlesUi.articlesCurrent === 'article-finder' ? 'is-current' : ''}>
                <Link data-key="article-finder" to={`/courses/${this.props.course_id}/articles#article-finder`} onClick={this.onNavClick}>Article Finder</Link>
              </li>
            </ol>
          </div>
        </Affix>
      </div>
    );
  }
});

const mapStateToProps = state => ({
  articlesUi: state.ui.articles,
  assignments: state.assignments.assignments,
  articles: state.articles.articles,
});

const mapDispatchToProps = {
  updateArticlesCurrent,
  toggleScrollDebounce,
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticlesNavbar);
