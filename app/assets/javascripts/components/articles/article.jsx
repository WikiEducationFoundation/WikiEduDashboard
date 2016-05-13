import React from 'react';

const Article = React.createClass({
  displayName: 'Article',

  propTypes: {
    article: React.PropTypes.object
  },

  render() {
    const className = 'article';
    const ratingClass = `rating ${this.props.article.rating}`;
    const ratingMobileClass = `${ratingClass} tabconst-only`;
    const languagePrefix = this.props.article.language ? `${this.props.article.language}:` : '';
    // The default project is Wikipedia.
    const project = this.props.article.project ? `${this.props.article.project}:` : 'wikipedia:';
    // Do not use a project prefix for Wikipedia.
    const projectPrefix = project === 'wikipedia:' ? '' : project;
    const formattedTitle = `${languagePrefix}${projectPrefix}${this.props.article.title}`;
    const historyUrl = `${this.props.article.url}?action=history`;

    return (
      <tr className={className}>
        <td className="popover-trigger desktop-only-tc">
          <p className="rating_num hidden">{this.props.article.rating_num}</p>
          <div className={ratingClass}><p>{this.props.article.pretty_rating || '-'}</p></div>
          <div className="popover dark">
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
        <td></td>
      </tr>
    );
  }
});

export default Article;
