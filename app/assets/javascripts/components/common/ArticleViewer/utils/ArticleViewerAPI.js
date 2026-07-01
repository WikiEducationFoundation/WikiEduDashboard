export class ArticleViewerAPI {
  constructor({ builder }) {
    this.builder = builder;
  }

  __processHtml(html) {
    if (!html) return undefined;

    // The mediawiki parse API returns the same HTML as the rendered article on
    // Wikipedia. This means relative links to other articles are broken.
    // Here we turn them into full urls pointing back to the wiki.
    // However, the page-local anchor links for footnotes and references are
    // fine; they should link to the footnotes within the ArticleViewer.
    const absoluteLink = `<a href="${this.builder.wikiURL()}/`;
    // This matches links that don't start with # or http. These are
    // assumed to be relative links to other wiki pages. It supports
    // an optional title attribute like `title="Property:P31"`, which is
    // included in Wikidata links, but will strip that title out.
    const relativeLinkMatcher = /(<a (title="[\w\d:]+" )?href=")(?!http)[^#]/g;
    return { html: html.replace(relativeLinkMatcher, absoluteLink) };
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

  fetchParsedArticle(lastRevisionId) {
    const url = this.builder.parsedArticleURL(lastRevisionId);
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
        // If this was a redirect, update the article title for subsequent API calls
        if (response.parse.redirects && response.parse.redirects.length > 0) {
          const redirectTarget = response.parse.redirects[0].to;
          this.builder.article.title = redirectTarget;
        }
        return {
          articlePageId: response.parse.pageid,
          fetched: true,
          parsedArticle: this.__processHtml(response.parse.text['*'])
        };
      });
  }
}

export default ArticleViewerAPI;
