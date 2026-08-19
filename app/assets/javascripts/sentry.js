window.Sentry = require('@sentry/browser');

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
