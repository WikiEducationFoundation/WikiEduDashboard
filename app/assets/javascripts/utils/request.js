import Rails from 'rails-ujs';
import fetch from 'cross-fetch';

export default (path, { method = 'GET', body = null } = {}) => {
  const options = {
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': Rails.csrfToken()
    },
    method
  };

  return fetch(path, body ? { body, ...options } : options);
};
