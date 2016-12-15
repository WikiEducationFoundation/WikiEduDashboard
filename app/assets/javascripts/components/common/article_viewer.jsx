import React from 'react';
import OnClickOutside from 'react-onclickoutside';

const ArticleViewer = React.createClass({
  displayName: 'ArticleViewer',

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
    if (!this.state.wikiwhoFetched) {
      // TODO: only do this for enwiki
      this.fetchWikiwho();
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

  wikiwhoUrl() {
    return `/wikiwho/${this.props.article.title}.json`;
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

  addWikiwhoData(html) {
    const tokens = this.state.wikiwho;
    let wikiwhoHtml = html;
    console.log(tokens)
    console.log('start regex')
    _.forEach(tokens, (token) => {
      // FIXME: somehow take these tokens and match them to the html to embed
      // authorship info.

      // const regexQuote = (token.str).replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&");
      // const matcher = new RegExp(`(${regexQuote})`, 'i');
      // wikiwhoHtml = wikiwhoHtml.replace(matcher, `<span author="${token.author}">$1</span>`);
    });
    console.log('end regex')

    return wikiwhoHtml;
  },

  fetchParsedArticle() {
    $.ajax({
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

  fetchWikiwho() {
    console.log('who?')
    $.ajax({
      url: this.wikiwhoUrl(),
      crossDomain: true,
      success: (json) => {
        this.setState({
          wikiwho: json.wikiwho,
          wikiwhoFetched: true
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

    let articleHtml;
    if (this.state.showArticle && this.state.wikiwhoFetched && this.state.fetched) {
      articleHtml = this.addWikiwhoData(this.state.parsedArticle);
    } else {
      articleHtml = this.state.parsedArticle;
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
          <div className="parsed-article" dangerouslySetInnerHTML={{ __html: articleHtml }} />
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
