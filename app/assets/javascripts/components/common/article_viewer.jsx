import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import OnClickOutside from 'react-onclickoutside';
import _ from 'lodash';

import { trunc } from '../../utils/strings';
import Loading from './loading.jsx';
import ArticleViewerLegend from './article_viewer_legend.jsx';

const ArticleViewer = createReactClass({
  displayName: 'ArticleViewer',

  propTypes: {
    article: PropTypes.object.isRequired,
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
      showArticle: false
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
  componentWillReceiveProps(nextProps) {
    if (!this.props.users && nextProps.users) {
      if (!this.state.userIdsFetched) {
        this.fetchUserIds(nextProps.users);
      }
    }
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

  wikiUrl() {
    return `https://${this.props.article.language || 'www'}.${this.props.article.project}.org`;
  },

  whocolorUrl() {
    return `https://api.wikiwho.net/${this.props.article.language}/whocolor/v1.0.0-beta/${this.props.article.title}/`;
  },

  parsedArticleUrl() {
    const wikiUrl = this.wikiUrl();
    const queryBase = `${wikiUrl}/w/api.php?action=parse&disableeditsection=true&format=json`;
    const articleUrl = `${queryBase}&page=${this.props.article.title}`;

    return articleUrl;
  },

  isWhocolorLang() {
    // Supported languages for https://api.wikiwho.net/ as of 2018-02-11
    const whocolorSupportedLang = ['de', 'en', 'es', 'eu', 'tr'];
    return whocolorSupportedLang.includes(this.props.article.language) && this.props.article.project === 'wikipedia';
  },

  processHtml(html, whocolor) {
    if (html && whocolor) {
      this.setState({ whocolorFetched: true });
    } else if (!html && whocolor) {
      return this.setState({ whocolorFailed: true });
    }
    // The mediawiki parse API returns the same HTML as the rendered article on
    // Wikipedia. This means relative links to other articles are broken.
    // Here we turn them into full urls pointing back to the wiki.
    // However, the page-local anchor links for footnotes and references are
    // fine; they should link to the footnotes within the ArticleViewer.
    const absoluteLink = `<a href="${this.wikiUrl()}/`;
    // This matches links that don't start with # or http. These are
    // assumed to be relative links to other wiki pages.
    const relativeLinkMatcher = /(<a href=")(?!http)[^#]/g;
    return html.replace(relativeLinkMatcher, absoluteLink);
  },

  colors: [
    'user-highlight-1', 'user-highlight-2', 'user-highlight-3', 'user-highlight-4',
    'user-highlight-5', 'user-highlight-6', 'user-highlight-7', 'user-highlight-8',
    'user-highlight-9', 'user-highlight-10', 'user-highlight-11', 'user-highlight-12',
    'user-highlight-13', 'user-highlight-14', 'user-highlight-15', 'user-highlight-16',
    'user-highlight-17', 'user-highlight-18', 'user-highlight-19', 'user-highlight-20',
    'user-highlight-21', 'user-highlight-22', 'user-highlight-23', 'user-highlight-24'
  ],

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
      const colorClass = this.colors[i];
      const styledAuthorSpan = `<span title="${user.name}" class="editor-token token-editor-${user.userid} ${colorClass}`;
      const authorSpanMatcher = new RegExp(`<span class="editor-token token-editor-${user.userid}`, 'g');
      html = html.replace(authorSpanMatcher, styledAuthorSpan);

      i += 1;
    });
    this.setState({
      highlightedHtml: html
    });
  },

  showException(jqXHR, exception) {
    let msg = '';
    if (jqXHR.status === 0) {
      msg = 'Not connect.\n Verify Network.';
    } else if (jqXHR.status.toString() === '404') {
      msg = 'Requested page not found. [404]';
    } else if (jqXHR.status.toString() === '500') {
      msg = 'Internal Server Error [500].';
    } else if (exception === 'parsererror') {
      msg = 'Requested JSON parse failed.';
    } else if (exception === 'timeout') {
      msg = 'Time out error.';
    } else if (exception === 'abort') {
      msg = 'Ajax request aborted.';
    } else {
      msg = `Uncaught Error.\n${jqXHR.responseText}`;
    }
    this.setState({
      whocolorFailed: true,
      failureMessage: msg
    });
  },

  fetchParsedArticle() {
    $.ajax({
      dataType: 'jsonp',
      url: this.parsedArticleUrl(),
      success: (data) => {
        this.setState({
          parsedArticle: this.processHtml(data.parse.text['*']),
          articlePageId: data.parse.pageid,
          fetched: true
        });
      },
      error: (jqXHR, exception) => this.showException(jqXHR, exception)
    });
  },

  fetchWhocolorHtml() {
    $.ajax({
      url: this.whocolorUrl(),
      crossDomain: true,
      success: (json) => {
        this.setState({
          whocolorHtml: this.processHtml(json.extended_html, true)
        });
        this.highlightAuthors();
      },
      error: (jqXHR, exception) => this.showException(jqXHR, exception)
    });
  },

  wikiUserQueryUrl(users) {
    const baseUrl = `${this.wikiUrl()}/w/api.php`;
    const usersParam = (users || this.props.users).join('|');
    return `${baseUrl}?action=query&list=users&format=json&ususers=${usersParam}`;
  },

  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  fetchUserIds(users) {
    $.ajax({
      dataType: 'jsonp',
      url: this.wikiUserQueryUrl(users),
      success: (json) => {
        this.setState({
          users: json.query.users,
          userIdsFetched: true
        });
      },
      error: (jqXHR, exception) => this.showException(jqXHR, exception)
    });
  },

  render() {
    if (!this.state.showArticle) {
      if (this.props.title) {
        return (
          <div className={`tooltip-trigger ${this.props.showButtonClass || ''}`}>
            <button onClick={this.showArticle}>{this.props.title}</button>
            <div className="tooltip tooltip-title dark large">
              <p>{this.showButtonLabel()}</p>
            </div>
          </div>
        );
      }
      return (
        <div className={`tooltip-trigger ${this.props.showButtonClass}`}>
          <button onClick={this.showArticle} className="icon icon-article-viewer" />
          <div className="tooltip tooltip-center dark large">
            <p>{this.showButtonLabel()}</p>
          </div>
        </div>
      );
    }
    const closeButton = <button onClick={this.hideArticle} className="pull-right article-viewer-button icon-close" />;

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
          colors={this.colors}
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
              {this.props.article.id && (
                <span><a className="icon-link" href={`?showArticle=${this.props.article.id}`} /></span>
              ) }
              {closeButton}
              <a className="button small pull-right article-viewer-button" href={`/feedback?subject=Article Viewer — ${this.props.article.title}`} target="_blank">How did the article viewer work for you?</a>
            </p>
          </div>
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

export default OnClickOutside(ArticleViewer);
