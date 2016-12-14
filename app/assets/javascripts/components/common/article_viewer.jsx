import React from 'react';
import OnClickOutside from 'react-onclickoutside';

const ArticleViewer = React.createClass({
  displayName: 'ArticleViweer',

  propTypes: {
    article: React.PropTypes.object.isRequired,
    showButtonLabel: React.PropTypes.string,
    hideButtonLabel: React.PropTypes.string,
    largeButton: React.PropTypes.bool
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

  parsedArticleUrl() {
    const wikiUrl = this.wikiUrl();
    const queryBase = `${wikiUrl}/api/rest_v1/page/html/`;
    const articleUrl = `${queryBase}${this.props.article.title}`;

    return articleUrl;
  },

  processHtml(html) {
    // The mediawiki RESTbase API can return html that uses the 'base' attribute
    // to correctly style the HTML of an article. However, the page-local anchor
    // links for footnotes and references are broken, because they use the 'base'
    // attribute and end up pointing to the wiki (on the wrong page).
    // To correct this, we replace all those page-local anchor links with absolute
    // links to the current location.
    const absoluteAnchorLink = `<a href="${window.location.href.split('#')[0]}#`;
    const samePageAnchorMatcher = /<a href="#/g;
    return html.replace(samePageAnchorMatcher, absoluteAnchorLink);
  },

  fetchParsedArticle() {
    $.ajax(
      {
        url: this.parsedArticleUrl(),
        crossDomain: true,
        success: (html) => {
          this.setState({
            parsedArticle: this.processHtml(html),
            fetched: true
          });
        }
      });
  },

  render() {
    let button;
    let showButtonStyle;
    if (this.props.largeButton) {
      showButtonStyle = 'button dark';
    } else {
      showButtonStyle = 'button dark small';
    }

    if (this.state.showArticle) {
      button = <button onClick={this.hideArticle} className="button dark small">{this.hideButtonLabel()}</button>;
    } else {
      button = <button onClick={this.showArticle} className={showButtonStyle}>{this.showButtonLabel()}</button>;
    }

    let articleModal;
    // Even if we have the content, we need to not render it — even hidden — or else
    // it will prevent other ajax request from working, since we include the whole
    // contents of a Wikipedia html page, including domain info that ajax uses.
    if (!this.state.parsedArticle || !this.state.showArticle) {
      articleModal = <div />;
    } else {
      articleModal = (
        <div className="article-viewer">
          <p>
            <a className="button dark small" href={this.props.article.url} target="_blank">{I18n.t('articles.view_on_wiki')}</a>
            {button}
            <a className="pull-right button small" href={`${window.location.origin}/feedback?subject=Article Viewer`} target="_blank">How did the article viewer work for you?</a>
          </p>
          <div className="parsed-article" dangerouslySetInnerHTML={{ __html: this.state.parsedArticle }} />
        </div>
      );
    }

    return (
      <div>
        {button}
        {articleModal}
      </div>
    );
  }
});

export default OnClickOutside(ArticleViewer);
