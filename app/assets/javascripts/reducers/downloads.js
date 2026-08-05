import { ADD_DOWNLOAD, UPDATE_DOWNLOAD, REMOVE_DOWNLOAD, MARK_DOWNLOADS_READ } from '../constants';

const STORAGE_KEY = 'wiki_edu_downloads';

const getInitialState = () => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      // Only restore downloads that are 'ready' or 'error' (not 'pending')
      // Pending downloads are lost on page reload since polling can't resume
      return {
        items: parsed.items.filter(item => item.status !== 'pending'),
        unreadCount: parsed.unreadCount
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

const saveToLocalStorage = (state) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
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
