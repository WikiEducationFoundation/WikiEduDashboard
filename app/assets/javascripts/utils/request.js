import fetch from 'cross-fetch';
import Rails from '@rails/ujs';

// it is a relative path if it doesn't start with http or https
const isRelativePath = path => !path.match(/^http(s?)/);

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

  return fetch(new URL(path, window.location.origin).href, body ? { body, ...options } : options);
};
