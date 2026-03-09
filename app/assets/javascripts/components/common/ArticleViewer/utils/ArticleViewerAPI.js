import fetch from 'cross-fetch';

// Simple in-memory cooldown cache to avoid hammering the WhoColor API when
// data is not yet available. Keyed by language|title|revision.
// Values are timestamps (ms) of last terminal failure.
const WHO_COLOR_FAILURE_CACHE = new Map();
const WHO_COLOR_COOLDOWN_MS = 5 * 60 * 1000; // 5 minutes

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
    // assumed to be relative links to other wiki pages. It supports
    // an optional title attribute like `title="Property:P31"`, which is
    // included in Wikidata links, but will strip that title out.
    const relativeLinkMatcher = /(<a (title="[\w\d:]+" )?href=")(?!http)[^#]/g;
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

  // This function sets up a timer for the request to the highlighting
  // API endpoint so that we can make requests on a delay.
  __wikiwhoColorURLTimedRequestPromise(timeout, lastRevisionId) {
    const url = this.builder.wikiwhoColorURL(lastRevisionId);
    return new Promise((resolve, reject) => {
      const headers = { 'Content-Type': 'application/javascript' };
      setTimeout(() => {
        fetch(`${url}?origin=*`, { headers })
          .then(response => (response.ok ? resolve(response) : reject(response)));
      }, timeout * 1000);
    });
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

  generateWhocolorHtml() {
    const url = this.builder.wikiwhoColorRevisionURL();
    return fetch(`${url}&origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response));
  }

  fetchWhocolorHtml(lastRevisionId) {
    let attempts = 0;
    const MAX_RETRY_ATTEMPTS = 5;

    // Before attempting network calls, short-circuit if we recently exhausted retries
    // for the same article+revision.
    const language = this.builder.article?.language;
    const title = this.builder.article?.title;
    const revisionKey = `${language}|${title}|${lastRevisionId || 0}`;
    const lastFailureAt = WHO_COLOR_FAILURE_CACHE.get(revisionKey);
    if (lastFailureAt && (Date.now() - lastFailureAt) < WHO_COLOR_COOLDOWN_MS) {
      return Promise.reject(new Error('WhoColor temporarily unavailable; retry later (cooldown active).'));
    }

    // This function is defined in this way so that the variable name
    // will be hoisted, allowing it to call itself.
    function colorURLRequest(attempt = 0) {
      // Exponential backoff with jitter (in seconds). First attempt has no delay.
      const baseDelay = attempt === 0 ? 0 : Math.min(30, 2 ** (attempt - 1));
      const jitter = attempt === 0 ? 0 : Math.random() * 0.5; // up to 0.5s extra
      const delaySeconds = baseDelay + jitter;

      return this.__wikiwhoColorURLTimedRequestPromise(delaySeconds, lastRevisionId)
        .then(response => response.json())
        .then((response) => {
          if (response.success) return Promise.resolve(response);

          // If the data isn't already available on the wikiwho server,
          // it may return a 200 response with `success: false`.
          // In this case, we will retry a few times.
          attempts += 1;
          if (attempts <= MAX_RETRY_ATTEMPTS) return colorURLRequest.call(this, attempts);

          // Handle the case when the key 'info' is not present in response.
          const info = response.info ? response.info : '';

          // Record terminal failure to cooldown subsequent attempts for this revision.
          WHO_COLOR_FAILURE_CACHE.set(revisionKey, Date.now());

          const err = `Request failed after ${MAX_RETRY_ATTEMPTS} attempts. ${info}`;
          throw new Error(err);
        });
    }

    return colorURLRequest.call(this)
      .then(response => this.__processHtml(response.extended_html, true));
  }

  fetchUserIds() {
    const url = this.builder.wikiUserQueryURL();
    return fetch(`${url}&origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response));
  }

  fetchWikitextMetaData() {
    const url = this.builder.wikiwhoColorRevisionURL();
    return fetch(`${url}&origin=*`, {
      headers: {
        'Content-Type': 'application/javascript'
      }
    }).then(response => this.__handleFetchResponse(response))
      .then((response) => {
        if (response.error) throw new Error(this.__setException({ status: 404 }));
        const revisionId = 'revisions'; // Get the first (and presumably only) revision ID
        const revisionData = response[revisionId]?.[0];
        if (!revisionData) throw new Error('Invalid response data');
        const { tokens } = Object.values(revisionData)[0];
        return { tokensForRevision: tokens };
      });
  }
}

export default ArticleViewerAPI;
