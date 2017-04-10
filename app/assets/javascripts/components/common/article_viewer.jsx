import React from 'react';
import OnClickOutside from 'react-onclickoutside';

const ArticleViewer = React.createClass({
  displayName: 'ArticleViewer',

  propTypes: {
    article: React.PropTypes.object.isRequired,
    showButtonLabel: React.PropTypes.string,
    hideButtonLabel: React.PropTypes.string,
    largeButton: React.PropTypes.bool,
    users: React.PropTypes.array
  },

  getInitialState() {
    return {
      showArticle: false
    };
  },

  showButtonLabel() {
    if (this.props.showButtonLabel) {
      return this.props.showButtonLabel;
    }
    return I18n.t('articles.show_current_version');
  },

  hideButtonLabel() {
    if (this.props.hideButtonLabel) {
      return this.props.hideButtonLabel;
    }
    return I18n.t('articles.hide');
  },

  showArticle() {
    this.setState({ showArticle: true });
    if (!this.state.fetched) {
      this.fetchParsedArticle();
    }
    if (!this.state.userIdsFetched) {
      // TODO: only do this for enwiki
      this.fetchUserIds();
    }
    if (!this.state.whocolorFetched) {
      // TODO: only do this for enwiki
      this.fetchWhocolorHtml();
    }
  },

  hideArticle() {
    this.setState({ showArticle: false });
  },

  handleClickOutside() {
    this.hideArticle();
  },

  wikiUrl() {
    return `https://${this.props.article.language}.${this.props.article.project}.org`;
  },

  whocolorUrl() {
    return `https://api.wikicolor.net/whocolor/index.php?title=${this.props.article.title}`;
  },

  parsedArticleUrl() {
    const wikiUrl = this.wikiUrl();
    const queryBase = `${wikiUrl}/w/api.php?action=parse&disableeditsection=true&format=json`;
    const articleUrl = `${queryBase}&page=${this.props.article.title}`;

    return articleUrl;
  },

  processHtml(html) {
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

  colors: ['user-highlight-1', 'user-highlight-2', 'user-highlight-3', 'user-highlight-4', 'user-highlight-5'],

  highlightAuthors() {
    let html = this.state.whocolorHtml;
    let i = 0;
    _.forEach(this.state.users, (user) => {
      // Move spaces inside spans, so that background color is continuous
      html = html.replace(/ (<span class="author-token.*?>)/g, '$1 ');
      const styledAuthorSpan = `<span title="${user.name}" class="author-token token-authorid-${user.userid} ${this.colors[i]}"`;
      const authorSpanMatcher = new RegExp(`<span class="author-token token-authorid-${user.userid}`, 'g');
      html = html.replace(authorSpanMatcher, styledAuthorSpan);
      i += 1;
    });
    this.setState({
      highlightedHtml: html
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
      }
    });
  },

  fetchWhocolorHtml() {
    $.ajax({
      url: this.whocolorUrl(),
      crossDomain: true,
      success: (json) => {
        this.setState({
          whocolorHtml: this.processHtml(json.html),
          whocolorFetched: true
        });
        this.highlightAuthors();
      }
    });
  },

  wikiUserQueryUrl() {
    const baseUrl = `https://${this.props.article.language}.${this.props.article.project}.org/w/api.php`;
    const usersParam = this.props.users.join('|');
    return `${baseUrl}?action=query&list=users&format=json&ususers=${usersParam}`;
  },

  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  fetchUserIds() {
    $.ajax({
      dataType: 'jsonp',
      url: this.wikiUserQueryUrl(),
      success: (json) => {
        this.setState({
          users: json.query.users,
          usersIdsFetched: true
        });
      }
    });
  },

  render() {
    let colorLegend;
    if (this.state.highlightedHtml) {
      const users = this.state.users.map((user, i) => {
        return (
          <div key={`legend-${user.name}`} className={`user-legend ${this.colors[i]}`}>
            {user.name}
          </div>
        );
      });
      colorLegend = (
        <div>
          {users}
        </div>
      );
    }
    let button;
    let showButtonStyle;
    if (this.props.largeButton) {
      showButtonStyle = 'button dark';
    } else {
      showButtonStyle = 'button dark small';
    }

    if (this.state.showArticle) {
      button = <button onClick={this.hideArticle} className="button dark small pull-right">{this.hideButtonLabel()}</button>;
    } else {
      button = <button onClick={this.showArticle} className={showButtonStyle}>{this.showButtonLabel()}</button>;
    }

    let style = 'hidden';
    if (this.state.showArticle && this.state.fetched) {
      style = '';
    }
    const className = `article-viewer ${style}`;

    let article;
    if (this.state.diff === '') {
      article = '<div />';
    } else {
      article = this.state.highlightedHtml || this.state.whocolorHtml || this.state.parsedArticle;
    }

    return (
      <div>
        {button}
        <div className={className}>
          <div className="article-header">
            <p>
              <span className="article-viewer-title">{this.props.article.title}</span>
              {button}
              <a className="button small pull-right" href="/feedback?subject=Article Viewer" target="_blank">How did the article viewer work for you?</a>
            </p>
          </div>
          <div className="article-scrollbox">
            <div className="parsed-article" dangerouslySetInnerHTML={{ __html: article }} />
          </div>
          <div className="article-footer">
            <a className="button dark small pull-right" href={this.props.article.url} target="_blank">{I18n.t('articles.view_on_wiki')}</a>
            {colorLegend}
          </div>
        </div>
      </div>
    );
  }
});

export default OnClickOutside(ArticleViewer);
