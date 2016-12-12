import React from 'react';
import UIStore from '../../stores/ui_store.js';
import UIActions from '../../actions/ui_actions.js';
import ServerActions from '../../actions/server_actions.js';
import ArticleDetailsStore from '../../stores/article_details_store.js';

const Article = React.createClass({
  displayName: 'Article',

  propTypes: {
    article: React.PropTypes.object.isRequired,
    course: React.PropTypes.object.isRequired
  },

  mixins: [UIStore.mixin],

  getInitialState() {
    return { is_open: false };
  },

  storeDidChange() {
    return this.setState({ is_open: UIStore.getOpenKey() === (`drawer_${this.props.article.id}`) });
  },

  openDrawer() {
    ArticleDetailsStore.clear();
    ServerActions.fetchArticleDetails(this.props.article.id, this.props.course.id);
    return UIActions.open(`drawer_${this.props.article.id}`);
  },

  shouldShowLanguagePrefix() {
    return this.props.article.language !== this.props.course.home_wiki.language;
  },

  shouldShowProjectPrefix() {
    return this.props.article.project !== this.props.course.home_wiki.project;
  },

  render() {
    let className = 'article';
    className += this.state.is_open ? ' open' : '';

    const ratingClass = `rating ${this.props.article.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const languagePrefix = this.shouldShowLanguagePrefix() ? `${this.props.article.language}:` : '';
    // The default project is Wikipedia.
    const project = this.shouldShowProjectPrefix() ? `${this.props.article.project}:` : 'wikipedia:';
    // Do not use a project prefix for Wikipedia.
    const projectPrefix = project === 'wikipedia:' ? '' : project;
    const formattedTitle = `${languagePrefix}${projectPrefix}${this.props.article.title}`;
    const historyUrl = `${this.props.article.url}?action=history`;

    return (
      <tr className={className} onClick={this.openDrawer}>
        <td className="tooltip-trigger desktop-only-tc">
          <p className="rating_num hidden">{this.props.article.rating_num}</p>
          <div className={ratingClass}><p>{this.props.article.pretty_rating || '-'}</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${this.props.article.rating || '?'}`)}</p>
          </div>
        </td>
        <td>
          <div className={ratingMobileClass}><p>{this.props.article.pretty_rating || '-'}</p></div>
          <p className="title">
            <a href={this.props.article.url} target="_blank" className="inline">{formattedTitle} {(this.props.article.new_article ? ` ${I18n.t('articles.new')}` : '')}</a>
            <br />
            <small><a href={historyUrl} target="_blank" className="inline">(history)</a></small>
          </p>
        </td>
        <td className="desktop-only-tc">{this.props.article.character_sum}</td>
        <td className="desktop-only-tc">{this.props.article.view_count}</td>
        <td><button className="icon icon-arrow table-expandable-indicator" ></button></td>
      </tr>
    );
  }
});

export default Article;
