import { ADD_DOWNLOAD, UPDATE_DOWNLOAD, REMOVE_DOWNLOAD, MARK_DOWNLOADS_READ } from '../constants';
import { pollReportCsv } from '../utils/csv_polling_utils';

// Tracks in-flight polling cancellations, keyed by download id, so that polling
// keeps running independently of whether any component is mounted.
const activePolls = {};

export const addDownload = download => ({ type: ADD_DOWNLOAD, download });
export const updateDownload = (id, changes) => ({ type: UPDATE_DOWNLOAD, id, changes });
export const removeDownload = (id) => {
  if (activePolls[id]) {
    activePolls[id]();
    delete activePolls[id];
  }
  return { type: REMOVE_DOWNLOAD, id };
};
export const markDownloadsRead = () => ({ type: MARK_DOWNLOADS_READ });

// Starts (or resumes polling for) a CSV download. The polling itself lives
// here rather than in a component, so it survives modal closes and route changes.
export const startDownload = ({ id, href, label, onGenerating }) => (dispatch, getState) => {
  // Already polling, e.g. resumed after a page load. Don't poll twice, but still
  // let the caller know the file is generating.
  if (activePolls[id]) {
    if (onGenerating) { onGenerating(); }
    return;
  }

  const state = getState ? getState() : null;
  const existingItem = state?.downloads?.items?.find(item => item.id === id);

  if (existingItem) {
    dispatch(updateDownload(id, { status: 'pending' }));
  } else {
    dispatch(addDownload({ id, href, label, status: 'pending', createdAt: Date.now() }));
  }

  let hasNotifiedGenerating = false;
  const cancel = pollReportCsv(href, {
    onGenerating: (data) => {
      if (!hasNotifiedGenerating) {
        hasNotifiedGenerating = true;
        if (onGenerating) {
          onGenerating(data);
        }
      }
    },
    onReady: (data) => {
      delete activePolls[id];
      const filename = data.url.split('/').pop() || `${label}.csv`;
      dispatch(updateDownload(id, { status: 'ready', downloadUrl: data.url, filename }));
    },
    onError: (err) => {
      delete activePolls[id];
      const status = err?.reason === 'timeout' ? 'timeout' : 'error';
      dispatch(updateDownload(id, { status }));
    }
  });

  activePolls[id] = cancel;
};

// Polling stops when the page unloads, so downloads restored as 'pending' from
// localStorage need their polling restarted on each page load.
export const resumePendingDownloads = () => (dispatch, getState) => {
  getState().downloads.items
    .filter(item => item.status === 'pending')
    .forEach(item => dispatch(startDownload(item)));
};
