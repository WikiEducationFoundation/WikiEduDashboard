import ArticleViewerAPI from '@components/common/ArticleViewer/utils/ArticleViewerAPI';

// Simple in-memory cooldown cache to avoid hammering the WhoColor API when
// data is not yet available. Keyed by language|title|revision.
// Values are timestamps (ms) of last terminal failure.
const WHO_COLOR_FAILURE_CACHE = new Map();
const WHO_COLOR_COOLDOWN_MS = 5 * 60 * 1000; // 5 minutes

// The authorship/WhoColor side of the article-viewer API. Extends ArticleViewerAPI
// to reuse its HTML/link processing and fetch-response helpers. The shell never
// imports this; only the authorship feature does.
export class AuthorshipAPI extends ArticleViewerAPI {
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
      .then((response) => {
        // The shell's __processHtml does the relative-link rewriting; if the
        // WhoColor payload lacked HTML, surface a failure marker (as before).
        const processed = this.__processHtml(response.extended_html);
        return processed || { whocolorFailed: true };
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

export default AuthorshipAPI;
