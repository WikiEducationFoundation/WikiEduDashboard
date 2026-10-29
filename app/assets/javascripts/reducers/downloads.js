import { ADD_DOWNLOAD, UPDATE_DOWNLOAD, REMOVE_DOWNLOAD, MARK_DOWNLOADS_READ } from '../constants';

const STORAGE_KEY_PREFIX = 'wiki_edu_downloads';
export const ONE_WEEK_MS = 7 * 24 * 60 * 60 * 1000;

export const getCurrentUserKey = () => {
  if (typeof document !== 'undefined') {
    const main = document.getElementById('main');
    const userId = main?.getAttribute('data-user-id');
    if (userId) {
      return userId;
    }
    const navRoot = document.getElementById('nav_root');
    const username = navRoot?.getAttribute('data-username');
    if (username) {
      return username;
    }
  }
  return 'guest';
};

export const getStorageKey = (userKey = getCurrentUserKey()) => {
  return `${STORAGE_KEY_PREFIX}_${userKey}`;
};

export const isExpired = (item) => {
  if (!item || !item.createdAt) return false;
  return (Date.now() - item.createdAt) > ONE_WEEK_MS;
};

export const getInitialState = (storageKey = getStorageKey()) => {
  try {
    const stored = typeof localStorage !== 'undefined' ? localStorage.getItem(storageKey) : null;
    if (stored) {
      const parsed = JSON.parse(stored);
      // Restore downloads that have not expired (> 1 week, matching CsvCleanupWorker).
      // 'pending' ones are kept too; resumePendingDownloads picks their polling back up.
      const items = (parsed.items || []).filter(item => !isExpired(item));
      return {
        items,
        unreadCount: Math.min(parsed.unreadCount || 0, items.length)
      };
    }
  } catch (e) {
    console.error('Failed to restore downloads from localStorage:', e);
  }
  return {
    items: [],
    unreadCount: 0
  };
};

export const saveToLocalStorage = (state, storageKey = getStorageKey()) => {
  try {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(storageKey, JSON.stringify(state));
    }
  } catch (e) {
    console.error('Failed to save downloads to localStorage:', e);
  }
};

const initialState = getInitialState();

export default function downloads(state = initialState, action) {
  let newState;

  switch (action.type) {
    case ADD_DOWNLOAD: {
      newState = {
        ...state,
        items: [action.download, ...state.items],
        unreadCount: state.unreadCount + 1
      };
      break;
    }
    case UPDATE_DOWNLOAD: {
      const wasUnready = state.items.some(
        item => item.id === action.id && item.status !== 'ready'
      );
      const becomesReady = action.changes.status === 'ready';
      newState = {
        ...state,
        items: state.items.map(item => (
          item.id === action.id ? { ...item, ...action.changes } : item
        )),
        unreadCount: wasUnready && becomesReady ? state.unreadCount + 1 : state.unreadCount
      };
      break;
    }
    case REMOVE_DOWNLOAD: {
      newState = {
        ...state,
        items: state.items.filter(item => item.id !== action.id)
      };
      break;
    }
    case MARK_DOWNLOADS_READ: {
      newState = {
        ...state,
        unreadCount: 0
      };
      break;
    }
    default:
      return state;
  }

  // Persist to localStorage after state changes
  if (newState) {
    saveToLocalStorage(newState);
  }

  return newState || state;
}
