window.Sentry = require('@sentry/browser');

// For an unhandled TypeError: Failed to fetch, finds the URL of the request
// that failed from Sentry's own automatic "fetch" breadcrumb, plus whether
// it was cross-origin (third-party APIs like wikidata.org are far more
// likely to be blocked by ad/privacy blockers than our own backend).
const failedFetchUrlInfo = (event) => {
  const breadcrumbs = event.breadcrumbs && event.breadcrumbs.values;
  const lastFetch = breadcrumbs && [...breadcrumbs].reverse().find(b => b.category === 'fetch');
  const url = lastFetch && lastFetch.data && lastFetch.data.url;
  if (!url) return { url: undefined, crossOrigin: undefined };
  try {
    return { url, crossOrigin: new URL(url, window.location.origin).origin !== window.location.origin };
  } catch (urlError) {
    return { url, crossOrigin: undefined };
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
    event.extra = {
      ...event.extra,
      onLine: navigator.onLine,
      visibilityState: document.visibilityState,
      hasServiceWorkerController: !!navigator.serviceWorker?.controller,
      ...failedFetchUrlInfo(event)
    };
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
