import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';

const Article = createReactClass({
  displayName: 'Article',

  propTypes: {
    article: PropTypes.object.isRequired,
    course: PropTypes.object.isRequired,
    isOpen: PropTypes.bool.isRequired,
    toggleDrawer: PropTypes.func.isRequired,
    fetchArticleDetails: PropTypes.func.isRequired,
    articleDetails: PropTypes.object
  },

  toggleDrawer() {
    if (!this.props.articleDetails) {
      this.props.fetchArticleDetails(this.props.article.id, this.props.course.id);
    }
    return this.props.toggleDrawer(`drawer_${this.props.article.id}`);
  },
  render() {
    let className = 'article';
    className += this.props.isOpen ? ' open' : '';

    const ratingClass = `rating ${this.props.article.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;

    // Uses Course Utils Helper
    const formattedTitle = CourseUtils.formattedArticleTitle(this.props.article, this.props.course.home_wiki);
    const historyUrl = `${this.props.article.url}?action=history`;

    return (
      <tr className={className} onClick={this.toggleDrawer}>
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
        <td><button className="icon icon-arrow table-expandable-indicator" /></td>
      </tr>
    );
  }
});

export default Article;
