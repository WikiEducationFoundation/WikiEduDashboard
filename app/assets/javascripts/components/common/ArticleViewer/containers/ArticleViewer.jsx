import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import OnClickOutside from 'react-onclickoutside';

// Utilities
import _ from 'lodash';
import { trunc } from '~/app/assets/javascripts/utils/strings';

// Components
import Loading from '@components/common/loading.jsx';
import ArticleViewerLegend from '@components/common/article_viewer_legend.jsx';
import TitleOpener from '@components/common/ArticleViewer/components/TitleOpener.jsx';
import IconOpener from '@components/common/ArticleViewer/components/IconOpener.jsx';
import CloseButton from '@components/common/ArticleViewer/components/CloseButton.jsx';
import Permalink from '@components/common/ArticleViewer/components/Permalink.jsx';
import BadWorkAlert from '../components/BadWorkAlert';
import BadWorkAlertButton from '@components/common/ArticleViewer/components/BadWorkAlertButton.jsx';
import ParsedArticle from '@components/common/ArticleViewer/components/ParsedArticle.jsx';

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

  hideBadArticleAlert() {
    this.setState({ showBadArticleAlert: false });
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
    this.hideBadArticleAlert();
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
    const { showButtonClass, showPermalink = true, title } = this.props;
    if (!this.state.showArticle) {
      if (title) {
        return (
          <TitleOpener
            showArticle={this.showArticle}
            showButtonClass={showButtonClass}
            showButtonLabel={this.showButtonLabel}
            title={title}
          />
        );
      }
      return (
        <IconOpener
          showArticle={this.showArticle}
          showButtonClass={showButtonClass}
          showButtonLabel={this.showButtonLabel}
        />
      );
    }

    let style = 'hidden';
    if (this.state.showArticle) {
      style = '';
    }
    const className = `article-viewer ${style}`;

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

    return (
      <div>
        <div className={className}>
          <div className="article-header">
            <p>
              <span className="article-viewer-title">{trunc(this.props.article.title, 56)}</span>
              {
                showPermalink && <Permalink articleId={this.props.article.id} />
              }
              <CloseButton hideArticle={this.hideArticle} />
              <BadWorkAlertButton showBadArticleAlert={this.showBadArticleAlert} />
            </p>
          </div>
          {
            this.state.showBadArticleAlert && (
              <BadWorkAlert submitBadWorkAlert={this.submitBadWorkAlert} />
            )
          }
          <div className="article-scrollbox">
            {
              this.state.fetched ? (
                <ParsedArticle {...this.state} />
              ) : (
                <Loading />
              )
            }
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
