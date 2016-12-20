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

  wikiwhoUrl() {
    return `/wikiwho/${this.props.article.title}.json`;
  },

  parsedArticleUrl() {
    const wikiUrl = this.wikiUrl();
    const queryBase = `${wikiUrl}/w/api.php?action=parse&disableeditsection=true&format=json`;
    const articleUrl = `${queryBase}&page=${this.props.article.title}`;

    return articleUrl;
  },

  articleMetadataUrl() {
    const wikiUrl = this.wikiUrl();
    const queryBase = `${wikiUrl}/w/api.php?action=query&prop=revisions&rvlimit=1&rvprop=ids|content&format=json`;
    const metadataUrl = `${queryBase}&titles=${this.props.article.title}`;

    return metadataUrl;
  },

  processWikiwhoData() {
    console.log('you do!')
  },

  fetchParsedArticle() {
    $.ajax({
      dataType: 'jsonp',
      url: this.parsedArticleUrl(),
      success: (data) => {
        this.setState({
          parsedArticle: data.parse.text['*'],
          articlePageId: data.parse.pageid,
          fetched: true
        });
        this.fetchArticleMetadata(); // TODO: only do this for enwiki
      }
    });
  },

  fetchArticleMetadata() {
    $.ajax({
      dataType: 'jsonp',
      url: this.articleMetadataUrl(),
      success: (data) => {
        console.log(data.query.pages[this.state.articlePageId].revisions[0]['*'])
        this.setState({
          articleMarkup: data.query.pages[this.state.articlePageId].revisions[0]['*'],
          metadataFetched: true
        });
      }
    });
  },

  fetchWikiwho() {
    console.log('voodoo')
    $.ajax({
      url: this.wikiwhoUrl(),
      crossDomain: true,
      success: (json) => {
        console.log('who do?')
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

    if (this.state.showArticle) {
      button = <button onClick={this.hideArticle} className="button dark small">{this.hideButtonLabel()}</button>;
    } else {
      button = <button onClick={this.showArticle} className={showButtonStyle}>{this.showButtonLabel()}</button>;
    }

    if (this.state.metadataFetched && this.state.wikiwhoFetched && !this.state.wikiwhoProcessed) {
      this.processWikiwhoData();
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
      // diff = this.state.diff;
      article = this.state.parsedArticle;
    }

    return (
      <div>
        {button}
        <div className={className}>
          <p>
            <a className="button dark small" href={this.props.article.url} target="_blank">{I18n.t('articles.view_on_wiki')}</a>
            {button}
            <a className="pull-right button small" href="/feedback?subject=Article Viewer" target="_blank">How did the article viewer work for you?</a>
          </p>
          <div className="parsed-article" dangerouslySetInnerHTML={{ __html: article }} />
        </div>
      </div>
    );
  }
});

export default OnClickOutside(ArticleViewer);
