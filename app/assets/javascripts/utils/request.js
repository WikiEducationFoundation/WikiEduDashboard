import Rails from 'rails-ujs';
import fetch from 'cross-fetch';

const isRelativePath = path => !path.match(/http(s?)/g);

export default (path, { method = 'GET', body = null } = {}) => {
  const options = {
    headers: {
      'Content-Type': 'application/json'
    },
    method
  };

  // If the path is an internal request, include the CSRF Token
  if (isRelativePath(path)) options.headers['X-CSRF-Token'] = Rails.csrfToken();
  return fetch(path, body ? { body, ...options } : options);
};
