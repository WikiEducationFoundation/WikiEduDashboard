import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from "react-redux";

import Affix from '../common/affix.jsx';

const ArticlesNavbar = createReactClass({
  render() {
    let availableArticlesNav;
    if (this.props.assignments.length > 0 || this.props.current_user.isNonstudent) {
      availableArticlesNav = (
        <li key="available-articles" className={this.props.currentElement === 'available-articles' ? 'is-current' : ''}>
          <a href="#available-articles" data-key="available-articles" onClick={this.props.onNavClick}>{I18n.t('articles.available')}</a>
        </li>
        );
    }
    return (
      <div className="articles-nav">
        <Affix offset={100}>
          <div className="panel">
            <ol>
              <li key="articles-edited" className={this.props.currentElement === 'articles-edited' ? 'is-current' : ''}>
                <a href="#articles-edited" data-key="articles-edited" onClick={this.props.onNavClick}>{I18n.t('metrics.articles_edited')}</a>
              </li>
              <li key="articles-assigned" className={this.props.currentElement === 'articles-assigned' ? 'is-current' : ''}>
                <a href="#articles-assigned" data-key="articles-assigned" onClick={this.props.onNavClick}>{I18n.t('articles.assigned')}</a>
              </li>
              {availableArticlesNav}
            </ol>
          </div>
        </Affix>
      </div>
    );
  }
});

export default ArticlesNavbar;
