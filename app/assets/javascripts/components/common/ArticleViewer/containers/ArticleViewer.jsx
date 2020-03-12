import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import OnClickOutside from 'react-onclickoutside';
import _ from 'lodash';

import { trunc } from '~/app/assets/javascripts/utils/strings';
import Loading from '@components/common/loading.jsx';
import ArticleViewerLegend from '@components/common/article_viewer_legend.jsx';

// Helpers
import URLBuilder from '@components/common/ArticleViewer/utils/URLBuilder';
import ArticleViewerAPI from '@components/common/ArticleViewer/utils/ArticleViewerAPI';

// Constants
import colors from '@components/common/ArticleViewer/constants/colors';

// Actions
import { submitBadWorkAlert } from '~/app/assets/javascripts/actions/alert_actions.js';

export const ArticleViewer = createReactClass({
  displayName: 'ArticleViewer',

  propTypes: {
    article: PropTypes.object.isRequired,
    course: PropTypes.object.isRequired,
    showButtonLabel: PropTypes.string,
    showButtonClass: PropTypes.string,
    title: PropTypes.string,
    users: PropTypes.array,
    showOnMount: PropTypes.bool,
    showArticleLegend: PropTypes.bool,
    fetchArticleDetails: PropTypes.func,
  },
  getDefaultProps() {
    return {
      showArticleFinder: false,
    };
  },

  getInitialState() {
    return {
      showArticle: false,
      showBadArticleAlert: false
    };
  },

  componentDidMount() {
    if (this.props.showOnMount) {
      this.showArticle();
    }
  },

  // When 'show' is clicked, this component may or may not already have
  // users data (a list of usernames) in its props. If it does, then 'show' will
  // fetch the MediaWiki user ids, which are used for coloration. Those can't be
  // fetched until the usernames are available, so 'show' will fetch the usernames
  // first in that case. In that case, componentWillReceiveProps fetches the
  // user ids as soon as usernames are avaialable.
  UNSAFE_componentWillReceiveProps(nextProps) {
    if (!this.props.users && nextProps.users) {
      if (!this.state.userIdsFetched) {
        this.fetchUserIds(nextProps.users);
      }
    }
  },

  showBadArticleAlert() {
    this.setState({ showBadArticleAlert: true });
  },

  showButtonLabel() {
    if (this.props.showArticleFinder) {
      return 'Brief preview of Article';
    }
    if (this.props.showButtonLabel) {
      return this.props.showButtonLabel;
    }
    if (this.isWhocolorLang()) {
      return I18n.t('articles.show_current_version_with_authorship_highlighting');
    }
    return I18n.t('articles.show_current_version');
  },

  // It takes the data sent as the parameter and appends to the current Url
  addParamToURL(urlParam) {
    if (this.props.showArticleFinder) { return; }
    window.history.pushState({}, '', `?showArticle=${urlParam}`);
  },

  // It takes a synthetic event to check if it exist
  // It checks if the node(viewer) doesn't exist
  // if either case is true, it removes all parameters from the URL(starting from the ?)
  removeParamFromURL(event) {
    if (this.props.showArticleFinder) { return; }
    const viewer = document.getElementsByClassName('article-viewer')[0];
    if (!viewer || event) {
      if (window.location.search) {
        window.history.replaceState(null, null, window.location.pathname);
      }
    }
  },

  showArticle() {
    this.setState({ showArticle: true });
    if (!this.state.fetched) {
      this.fetchParsedArticle();
    }

    if (!this.props.users && !this.props.showArticleFinder) {
      this.props.fetchArticleDetails();
    } else if (!this.state.userIdsFetched && !this.props.showArticleFinder) {
      this.fetchUserIds(this.props.users);
    }
    // WhoColor is only available for some languages
    if (!this.state.whocolorFetched && this.isWhocolorLang()) {
      this.fetchWhocolorHtml();
    }
    // Add article id in the URL
    this.addParamToURL(this.props.article.id);
  },

  hideArticle(e) {
    this.setState({ showArticle: false });
    // removes the article parameter from the URL
    this.removeParamFromURL(e);
  },

  handleClickOutside() {
    this.hideArticle();
  },

  isWhocolorLang() {
    // Supported languages for https://api.wikiwho.net/ as of 2018-02-11
    const whocolorSupportedLang = ['de', 'en', 'es', 'eu', 'tr'];
    return whocolorSupportedLang.includes(this.props.article.language) && this.props.article.project === 'wikipedia';
  },

  // This takes the extended_html from the whoColor API, and replaces the span
  // annotations with ones that are more convenient to style in React.
  // The matching and replacing of spans is tightly coupled to the span format
  // provided by the whoColor API: https://github.com/wikiwho/WhoColor
  highlightAuthors() {
    let html = this.state.whocolorHtml;
    if (!html) { return; }

    let i = 0;
    _.forEach(this.state.users, (user) => {
      // Move spaces inside spans, so that background color is continuous
      html = html.replace(/ (<span class="editor-token.*?>)/g, '$1 ');

      // Replace each editor span for this user with one that includes their
      // username and color class.
      const colorClass = colors[i];
      const styledAuthorSpan = `<span title="${user.name}" class="editor-token token-editor-${user.userid} ${colorClass}`;
      const authorSpanMatcher = new RegExp(`<span class="editor-token token-editor-${user.userid}`, 'g');
      html = html.replace(authorSpanMatcher, styledAuthorSpan);

      i += 1;
    });
    this.setState({
      highlightedHtml: html
    });
  },

  fetchParsedArticle() {
    const builder = new URLBuilder({ article: this.props.article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchParsedArticle()
      .then((response) => {
        this.setState({
          ...response,
          parsedArticle: response.parsedArticle.html
        });
      }).catch((error) => {
        this.setState({
          failureMessage: error.message,
          fetched: true,
          whocolorFailed: true,
        });
      });
  },

  fetchWhocolorHtml() {
    const builder = new URLBuilder({ article: this.props.article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchWhocolorHtml()
       .then((response) => {
         this.setState({ whocolorHtml: response.html });
         this.highlightAuthors();
       }).catch((error) => {
         this.setState({
           whocolorFailed: true,
           failureMessage: error.message
         });
       });
  },

  submitBadWorkAlert() {
    this.props.submitBadWorkAlert({
      article_id: this.props.article.id,
      course_id: this.props.course.id
    });
  },

  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  fetchUserIds(users) {
    const builder = new URLBuilder({ article: this.props.article, users });
    const api = new ArticleViewerAPI({ builder });
    api.fetchUserIds()
      .then((response) => {
        this.setState({
          users: response.query.users,
          userIdsFetched: true
        });
      }).catch((error) => {
        this.setState({
          failureMessage: error.message,
          fetched: true,
          whocolorFailed: true,
        });
      });
  },

  render() {
    if (!this.state.showArticle) {
      if (this.props.title) {
        return (
          <div className={`tooltip-trigger ${this.props.showButtonClass || ''}`}>
            <button onClick={this.showArticle} aria-describedby="icon-article-viewer-desc">{this.props.title}</button>
            <p id="icon-article-viewer-desc">Open Article Viewer</p>
            <div className="tooltip tooltip-title dark large">
              <p>{this.showButtonLabel()}</p>
            </div>
          </div>
        );
      }
      return (
        <div className={`tooltip-trigger ${this.props.showButtonClass}`}>
          <button onClick={this.showArticle} aria-label="Open Article Viewer" className="icon icon-article-viewer" />
          <div className="tooltip tooltip-center dark large">
            <p>{this.showButtonLabel()}</p>
          </div>
        </div>
      );
    }
    const closeButton = <button onClick={this.hideArticle} className="pull-right article-viewer-button icon-close" aria-label="Close Article Viewer" />;

    let style = 'hidden';
    if (this.state.showArticle) {
      style = '';
    }
    const className = `article-viewer ${style}`;

    let article;
    if (this.state.fetched) {
      const articleHTML = this.state.highlightedHtml || this.state.whocolorHtml || this.state.parsedArticle;
      article = <div className="parsed-article" dangerouslySetInnerHTML={{ __html: articleHTML }} />;
    } else {
      article = <Loading />;
    }

    let legendStatus;
    if (this.state.highlightedHtml) {
      legendStatus = 'ready';
    } else if (this.state.whocolorFailed) {
      legendStatus = 'failed';
    } else if (this.isWhocolorLang()) {
      legendStatus = 'loading';
    }

    let articleViewerLegend;
    if (!this.props.showArticleFinder) {
      articleViewerLegend = (
        <ArticleViewerLegend
          article={this.props.article}
          users={this.state.users}
          colors={colors}
          status={legendStatus}
          failureMessage={this.state.failureMessage}
        />
      );
    }
    const { showPermalink = true } = this.props;
    return (
      <div>
        <div className={className}>
          <div className="article-header">
            <p>
              <span className="article-viewer-title">{trunc(this.props.article.title, 56)}</span>
              {
                showPermalink && (
                  <span>
                    <a className="icon-link" href={`?showArticle=${this.props.article.id}`} />
                  </span>
                )
              }

              {closeButton}
              <a
                className="button danger small pull-right article-viewer-button"
                onClick={() => this.showBadArticleAlert()}
              >
                Report Unsatisfactory Work
              </a>
            </p>
          </div>
          {
            this.state.showBadArticleAlert && (
              <div className="article-alert">
                <p>Click this button if you believe the work completed by your students needs intervention by a staff member of Wiki Education Foundation. A member of our staff will get in touch with you and your students.</p>
                <button
                  className="button danger"
                  onClick={() => this.submitBadWorkAlert()}
                >
                  Notify Wiki Expert
                </button>
              </div>
            )
          }
          <div className="article-scrollbox">
            {article}
          </div>
          <div className="article-footer">
            {articleViewerLegend}
            <a className="button dark small pull-right article-viewer-button" href={this.props.article.url} target="_blank">{I18n.t('articles.view_on_wiki')}</a>
          </div>
        </div>
      </div>
    );
  }
});

const clickOutsideComponent = OnClickOutside(ArticleViewer);
const mapDispatchToProps = {
  submitBadWorkAlert
};
export default connect(null, mapDispatchToProps)(clickOutsideComponent);
