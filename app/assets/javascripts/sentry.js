window.Sentry = require('@sentry/browser');

// For an unhandled TypeError: Failed to fetch, finds the URL of the request
// that actually failed from Sentry's own automatic "fetch" breadcrumbs, plus
// whether it was cross-origin (third-party APIs are far more likely to be
// blocked by ad/privacy blockers than our own backend). Breadcrumbs land in
// settle order, not failure order, so if another request (e.g. a concurrent
// one from the same page, or just the next unrelated fetch) settles after
// the failed one, the most recent 'fetch' breadcrumb isn't necessarily the
// failed one. The failed one is tagged level: 'error' with no status_code
// (see @sentry/browser's breadcrumbs integration), so filter on that instead.
const failedFetchUrlInfo = (event) => {
  const breadcrumbs = event.breadcrumbs && event.breadcrumbs.values;
  const lastFailedFetch = breadcrumbs &&
    [...breadcrumbs].reverse().find(b => b.category === 'fetch' && b.level === 'error');
  const failedUrl = lastFailedFetch && lastFailedFetch.data && lastFailedFetch.data.url;
  if (!failedUrl) return { failedUrl: undefined, crossOrigin: undefined };
  try {
    return { failedUrl, crossOrigin: new URL(failedUrl, window.location.origin).origin !== window.location.origin };
  } catch (urlError) {
    return { failedUrl, crossOrigin: undefined };
  }
};

// Normalizes non-Error promise rejections (e.g. a raw fetch Response, or a
// plain object) into a readable message on the event Sentry already built,
// instead of reporting them separately. Sentry's own unhandledrejection
// instrumentation assigns window.onunhandledrejection directly and does not
// check event.preventDefault(), so a parallel
// addEventListener('unhandledrejection', ...) here would just produce a
// second, duplicate Sentry event per rejection. This is wired in as
// Sentry.init's beforeSend in _head.html.haml.
window.normalizeUnhandledRejection = (event, hint) => {
  const firstException = event.exception && event.exception.values && event.exception.values[0];
  const mechanism = firstException && firstException.mechanism;
  if (!mechanism || mechanism.type !== 'onunhandledrejection') return event;

  const reason = hint && hint.originalException;

  // Network-level fetch failures (no HTTP response at all) are real Error
  // instances already, so they'd otherwise pass through the check below
  // unmodified. Enrich them with context that separates a dropped connection
  // or backgrounded tab from an actually blocked/intercepted request, and
  // aggregate every call site's occurrences into one issue instead of letting
  // them split by stack trace (see #7018).
  if (reason instanceof TypeError && reason.message === 'Failed to fetch') {
    const { failedUrl, crossOrigin } = failedFetchUrlInfo(event);
    // Low-cardinality fields go in tags, since extra isn't searchable or
    // aggregatable in Sentry -- that's what would let the offline-vs-blocked
    // split actually be analyzed instead of read event-by-event.
    event.tags = {
      ...event.tags,
      onLine: navigator.onLine,
      visibilityState: document.visibilityState,
      hasServiceWorkerController: !!navigator.serviceWorker?.controller,
      crossOrigin
    };
    // failedUrl (not `url`, which is Sentry's own tag for the page URL)
    // is high-cardinality, so it stays in extra.
    event.extra = { ...event.extra, failedUrl };
    event.fingerprint = ['unhandled-failed-to-fetch'];
    return event;
  }

  if (reason instanceof Error) return event;

  let message;
  if (reason && typeof reason === 'object' && 'status' in reason) {
    message = reason.statusText || `Request failed with status ${reason.status}`;
  } else {
    try {
      message = JSON.stringify(reason);
    } catch (stringifyError) {
      message = String(reason);
    }
  }

  firstException.type = 'UnhandledRejection';
  firstException.value = `Unhandled rejection: ${message}`;
  return event;
};
