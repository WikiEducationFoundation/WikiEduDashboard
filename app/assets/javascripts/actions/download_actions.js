import { ADD_DOWNLOAD, UPDATE_DOWNLOAD, REMOVE_DOWNLOAD, MARK_DOWNLOADS_READ } from '../constants';

const INITIAL_POLL_DELAY_MS = 100; // First check after 100ms for small files
const POLL_INTERVAL_MS = 1000; // Then check every 1 second
const MAX_POLL_ATTEMPTS = 300; // Max 5 minutes of polling

// Tracks in-flight polling intervals, keyed by download id, so that polling
// keeps running independently of whether any component is mounted.
const activePolls = {};
const pollAttempts = {};

export const addDownload = download => ({ type: ADD_DOWNLOAD, download });
export const updateDownload = (id, changes) => ({ type: UPDATE_DOWNLOAD, id, changes });
export const removeDownload = id => ({ type: REMOVE_DOWNLOAD, id });
export const markDownloadsRead = () => ({ type: MARK_DOWNLOADS_READ });

const isStillGenerating = async (response) => {
  // If the file exists, the response will be a binary/CSV file, not text/plain
  // Only text/plain responses with the "generating" message mean it's still pending
  const contentType = response.headers.get('content-type') || '';
  if (!contentType.includes('text/plain')) {
    // It's a CSV file (application/octet-stream or text/csv), so it's ready
    return false;
  }
  const text = await response.text();
  return text.includes('This file is being generated');
};

// Starts (or resumes polling for) a CSV download. The polling itself lives
// here rather than in a component, so it survives modal closes and route changes.
export const startDownload = ({ id, href, label }) => async (dispatch) => {
  if (activePolls[id]) { return; }

  dispatch(addDownload({ id, href, label, status: 'pending', createdAt: Date.now() }));

  pollAttempts[id] = 0;

  const poll = async () => {
    pollAttempts[id]++;

    try {
      const response = await fetch(href, { credentials: 'include' });

      if (await isStillGenerating(response)) {
        // Still generating, check if we've exceeded max attempts
        if (pollAttempts[id] >= MAX_POLL_ATTEMPTS) {
          clearInterval(activePolls[id]);
          delete activePolls[id];
          delete pollAttempts[id];
          dispatch(updateDownload(id, { status: 'error' }));
        }
        return;
      }

      clearInterval(activePolls[id]);
      delete activePolls[id];
      delete pollAttempts[id];

      const filename = response.url.split('/').pop() || `${label}.csv`;

      dispatch(updateDownload(id, { status: 'ready', downloadUrl: response.url, filename }));
    } catch {
      clearInterval(activePolls[id]);
      delete activePolls[id];
      delete pollAttempts[id];
      dispatch(updateDownload(id, { status: 'error' }));
    }
  };

  // First check immediately after a short delay for small files
  setTimeout(poll, INITIAL_POLL_DELAY_MS);

  // Then set up interval for subsequent checks
  activePolls[id] = setInterval(poll, POLL_INTERVAL_MS);
};
