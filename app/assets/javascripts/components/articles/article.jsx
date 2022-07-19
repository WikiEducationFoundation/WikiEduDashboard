import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';
import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';
import DiffViewer from '../revisions/diff_viewer.jsx';
import ArticleGraphs from './article_graphs.jsx';
import Switch from 'react-switch';
import { toWikiDomain } from '../../utils/wiki_utils.js';
import { stringify } from 'query-string';

const Article = createReactClass({
  displayName: 'Article',

  propTypes: {
    article: PropTypes.object.isRequired,
    index: PropTypes.number,
    course: PropTypes.object.isRequired,
    fetchArticleDetails: PropTypes.func.isRequired,
    updateArticleTrackedStatus: PropTypes.func,
    articleDetails: PropTypes.object,
    wikidataLabel: PropTypes.string,
    showOnMount: PropTypes.bool,
    setSelectedIndex: PropTypes.func,
    lastIndex: PropTypes.number,
    selectedIndex: PropTypes.number,
    deletedMessage: PropTypes.string
  },

  getInitialState() {
    return {
      tracked: this.props.article.tracked
    };
  },

  fetchArticleDetails() {
    if (!this.props.articleDetails) {
      this.props.fetchArticleDetails(this.props.article.id, this.props.course.id);
    }
  },

  handleTrackedChange(tracked) {
    this.props.updateArticleTrackedStatus(this.props.article.id, this.props.course.id, tracked);
    this.setState({ tracked });
  },

  render() {
    const ratingClass = `rating ${this.props.article.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const isDeleted = this.props.article.deleted;
    const wiki = {
      language: this.props.article.language,
      project: this.props.article.project
    };
    const pageLogURL = `https://${toWikiDomain(wiki)}/wiki/Special:Log?${stringify({
      page: this.props.article.title
    })}`;
    // Uses Course Utils Helper
    const formattedTitle = CourseUtils.formattedArticleTitle(this.props.article, this.props.course.home_wiki, this.props.wikidataLabel);
    const historyUrl = `${this.props.article.url}?action=history`;

    const trackedEditable = this.props.current_user && this.props.current_user.isAdvancedRole;

    let tracked;
    if (this.props.course.type !== 'ClassroomProgramCourse' && trackedEditable) {
      tracked = (
        <td className="tracking">
          <Switch onChange={this.handleTrackedChange} checked={this.state.tracked} onColor="#676eb4" />
        </td>
      );
    }

    let contentAdded;
    if (this.props.course.home_wiki_bytes_per_word) {
      const wordsAdded = Math.round(this.props.article.character_sum / this.props.course.home_wiki_bytes_per_word);
      contentAdded = <td className="desktop-only-tc">{wordsAdded}</td>;
    } else {
      contentAdded = <td className="desktop-only-tc">{this.props.article.character_sum}</td>;
    }

    const { project, title } = this.props.article;
    let { language } = this.props.article;
    if (project === 'wikidata') language = 'www';
    const pageviewUrl = `https://pageviews.toolforge.org/?project=${language}.${project}.org&platform=all-access&agent=user&range=latest-90&pages=${title}`;

    const isWikipedia = project === 'wikipedia';

    return (
      <tr className={`article ${isDeleted ? 'deleted' : ' '}`}>
        <td className="tooltip-trigger desktop-only-tc">
          {isWikipedia && <p className="rating_num hidden">{this.props.article.rating_num}</p>}
          {isWikipedia && <div className={ratingClass}><p>{!isDeleted ? (this.props.article.pretty_rating || '-') : 'DE'}</p></div>}
          {isWikipedia && <div className="tooltip dark">
            <p>
              {
                !isDeleted ? I18n.t(`articles.rating_docs.${this.props.article.rating || '?'}`, { class: this.props.article.rating || '' }) : this.props.deletedMessage
              }
            </p>
            {/* eslint-disable-next-line */}
          </div>}
        </td>
        <td>
          {isWikipedia && <div className={ratingMobileClass}><p>{!isDeleted ? (this.props.article.pretty_rating || '-') : 'DE'}</p></div>}
          {isWikipedia && <div />}
          <div className="title">
            <a href={this.props.article.url} target="_blank" className="inline">{formattedTitle} {(this.props.article.new_article ? ` ${I18n.t('articles.new')}` : '')}</a>
            <br />
            {!isDeleted
              ? (
                <small>
                  <a href={historyUrl} target="_blank" className="inline">{I18n.t('articles.history')}</a> | <ArticleGraphs article={this.props.article} />
                </small>
              )
              : (
                <small>
                  <a href={pageLogURL} target="_blank" className="inline">{this.props.pageLogsMessage}</a>
                </small>
              )
            }
          </div>
        </td>
        {contentAdded}
        <td className="desktop-only-tc">{this.props.article.references_count || ''}</td>
        <td className="desktop-only-tc">
          <a href={pageviewUrl} target="_blank" className="inline">{this.props.article.view_count}</a>
        </td>
        <td>
          <ArticleViewer
            article={this.props.article}
            course={this.props.course}
            current_user={this.props.current_user}
            users={this.props.articleDetails && this.props.articleDetails.editors}
            fetchArticleDetails={this.fetchArticleDetails}
            showButtonClass="pull-left"
            showOnMount={this.props.showOnMount}
          />
          <DiffViewer
            fetchArticleDetails={this.fetchArticleDetails}
            index={this.props.index}
            revision={this.props.articleDetails && this.props.articleDetails.last_revision}
            first_revision={this.props.articleDetails && this.props.articleDetails.first_revision}
            showButtonLabel={I18n.t('articles.show_cumulative_changes')}
            showButtonClass="pull-right"
            editors={this.props.articleDetails && this.props.articleDetails.editors}
            showSalesforceButton={Boolean(Features.wikiEd && this.props.current_user.admin)}
            course={this.props.course}
            article={this.props.article}
            articleTitle={this.props.article.title}
            setSelectedIndex={this.props.setSelectedIndex}
            lastIndex={this.props.lastIndex}
            selectedIndex={this.props.selectedIndex}
          />
        </td>
        {tracked}
      </tr>
    );
  }
});

export default Article;
