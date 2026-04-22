import request from '../utils/request';

const base = '/training_module_drafts';

const jsonHeaders = { 'Content-Type': 'application/json', Accept: 'application/json' };

const handleResponse = async (response) => {
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    const error = new Error(body.error || `Request failed (${response.status})`);
    error.status = response.status;
    throw error;
  }
  return response.json();
};

export const listDrafts = () =>
  request(`${base}.json`, { headers: jsonHeaders }).then(handleResponse);

export const getDraft = slug =>
  request(`${base}/${encodeURIComponent(slug)}.json`, { headers: jsonHeaders })
    .then(handleResponse);

export const createDraft = attrs =>
  request(base, {
    method: 'POST',
    body: JSON.stringify({ draft: attrs }),
    headers: jsonHeaders
  }).then(handleResponse);

export const updateDraft = (slug, attrs) =>
  request(`${base}/${encodeURIComponent(slug)}`, {
    method: 'PATCH',
    body: JSON.stringify({ draft: attrs }),
    headers: jsonHeaders
  }).then(handleResponse);

export const deleteDraft = slug =>
  request(`${base}/${encodeURIComponent(slug)}`, {
    method: 'DELETE',
    headers: jsonHeaders
  }).then(handleResponse);

export const parsePaste = markdown =>
  request(`${base}/parse_paste`, {
    method: 'POST',
    body: JSON.stringify({ markdown }),
    headers: jsonHeaders
  }).then(handleResponse);

export const getCollisions = slug =>
  request(`${base}/${encodeURIComponent(slug)}/collisions`, { headers: jsonHeaders })
    .then(handleResponse);

export const getExistingSlideSlugs = () =>
  request(`${base}/existing_slide_slugs.json`, { headers: jsonHeaders })
    .then(handleResponse);

export const exportUrl = slug => `${base}/${encodeURIComponent(slug)}/export`;
