import fetch from 'cross-fetch';

export class ArticleViewerAPI {
  constructor({ builder }) {
    this.builder = builder;
  }

  __whocolorStatus(html, whocolor) {
    if (html && whocolor) {
      return { whocolorFetched: true };
    } else if (!html && whocolor) {
      return { whocolorFailed: true };
    }
  }

  __processHtml(html, whocolor) {
    const status = this.__whocolorStatus(html, whocolor);
    if (!html) return status;

    // The mediawiki parse API returns the same HTML as the rendered article on
    // Wikipedia. This means relative links to other articles are broken.
    // Here we turn them into full urls pointing back to the wiki.
    // However, the page-local anchor links for footnotes and references are
    // fine; they should link to the footnotes within the ArticleViewer.
    const absoluteLink = `<a href="${this.builder.wikiURL()}/`;
    // This matches links that don't start with # or http. These are
    // assumed to be relative links to other wiki pages.
    const relativeLinkMatcher = /(<a href=")(?!http)[^#]/g;
    return {
      html: html.replace(relativeLinkMatcher, absoluteLink),
      ...status
    };
  }

  __setException(response) {
    if (response.status === 0) {
      return 'Not connect.\n Verify Network.';
    } else if (response.status.toString() === '404') {
      return 'Requested page not found. [404]';
    } else if (response.status.toString() === '500') {
      return 'Internal Server Error [500].';
    }

    return `Uncaught Error.\n${response.statusText}`;
  }

  __handleFetchResponse(response) {
    if (!response.ok) throw new Error(this.__setException(response));
    return response.json();
  }

  fetchParsedArticle() {
    const url = this.builder.parsedArticleURL();
    // Adding `origin=*` allows for requests to go to en.wikipedia.org
    // as referenced by this URL:
    // https://www.mediawiki.org/wiki/API:Cross-site_requests#CORS_usage
    return fetch(`${url}&origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response))
      .then((response) => {
        if (response.error) throw new Error(this.__setException({ status: 404 }));
        return {
          articlePageId: response.parse.pageid,
          fetched: true,
          parsedArticle: this.__processHtml(response.parse.text['*'])
        };
      });
  }

  generateWhocolorHtml() {
    const url = this.builder.wikiwhoColorRevisionURL();
    return fetch(`${url}&origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response));
  }

  fetchWhocolorHtml() {
    const url = this.builder.wikiwhoColorURL();
    const colorRequest = () => fetch(`${url}?origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response));

    return colorRequest()
      .then((response) => {
        if (response.success) return Promise.resolve(response);

        // If the data isn't already available on the wikiwho server,
        // it may return a 200 response with `success: false`.
        // In this case, requesting the `rev_content` for the article
        // usually causes a subsequent request for the extented html to
        // succeed.
        return this.generateWhocolorHtml().then(() => colorRequest());
      })
      .then((response) => {
        return this.__processHtml(response.extended_html, true);
      });
  }

  fetchUserIds() {
    const url = this.builder.wikiUserQueryURL();
    return fetch(`${url}&origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response));
  }
}

export default ArticleViewerAPI;
