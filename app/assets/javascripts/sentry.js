window.Sentry = require('@sentry/browser');

// Safety net for promise rejections that aren't Error instances (e.g. a
// bug throws a raw fetch Response or plain object). Sentry's default
// unhandled-rejection handler reports those as an opaque, stack-less
// "Non-Error exception captured" with a message like "[object Response]".
// Wrap the reason in a real Error first so Sentry gets a real message.
window.addEventListener('unhandledrejection', (event) => {
  const reason = event.reason;
  if (reason instanceof Error) return;

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

  const error = new Error(`Unhandled rejection: ${message}`);
  error.name = 'UnhandledRejection';

  event.preventDefault();
  if (typeof Sentry !== 'undefined') {
    Sentry.captureException(error, { extra: { reason } });
  } else {
    console.error(error, reason);
  }
});
