import Rails from '@rails/ujs';
import logErrorMessage from './log_error_message';

// it is a relative path if it doesn't start with http or https
const isRelativePath = path => !path.match(/^http(s?)/);

// Thrown by ensureOk instead of the raw Response, so failed requests surface
// in Sentry (and anywhere else that inspects errors) as a real Error with a
// message and stack trace, rather than as an unhandled "[object Response]".
export class ApiError extends Error {
  constructor(response, responseText) {
    super(response.statusText || `Request failed with status ${response.status}`);
    this.name = 'ApiError';
    this.status = response.status;
    this.statusText = response.statusText;
    this.url = response.url;
    this.responseText = responseText;
  }
}

// Call this after every fetch/request instead of hand-rolling
// `if (!response.ok) { ...; throw response; }`. Preserves response.status,
// statusText, url, and responseText for existing catch handlers that read
// those fields off the thrown value.
export const ensureOk = async (response, prefix) => {
  if (!response.ok) {
    logErrorMessage(response, prefix);
    const responseText = await response.text().catch(() => '');
    throw new ApiError(response, responseText);
  }
  return response;
};

export default (path, { method = 'GET', body = null, ...extraOptions } = {}) => {
  const options = {
    headers: {
      'Content-Type': 'application/json'
    },
    method,
    ...extraOptions
  };
  // If the path is an internal request, include the CSRF Token
  if (isRelativePath(path)) options.headers['X-CSRF-Token'] = Rails.csrfToken();

  return fetch(new URL(path, window.location.origin).href, body ? { body, ...options } : options)
    .then((response) => {
      const originalJson = response.json.bind(response);
      response.json = () => originalJson().catch((err) => {
        err.requestUrl = response.url;
        throw err;
      });
      return response;
    });
};
