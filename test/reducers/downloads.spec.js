import deepFreeze from 'deep-freeze';
import downloads, {
  getInitialState,
  getStorageKey,
  ONE_WEEK_MS
} from '../../app/assets/javascripts/reducers/downloads';
import {
  ADD_DOWNLOAD,
  UPDATE_DOWNLOAD,
  REMOVE_DOWNLOAD,
  MARK_DOWNLOADS_READ
} from '../../app/assets/javascripts/constants';

describe('downloads reducer', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  describe('initial state and localStorage scoping', () => {
    test('returns empty items and 0 unreadCount when localStorage is empty', () => {
      const state = getInitialState('wiki_edu_downloads_test_user');
      expect(state.items).toEqual([]);
      expect(state.unreadCount).toBe(0);
    });

    test('scopes localStorage key by user', () => {
      expect(getStorageKey('42')).toBe('wiki_edu_downloads_42');
      expect(getStorageKey('alice')).toBe('wiki_edu_downloads_alice');
    });

    test('restores saved items, including pending ones, and unread count from scoped key', () => {
      const savedData = {
        items: [
          { id: '1', status: 'ready', label: 'Report', createdAt: Date.now() },
          { id: '2', status: 'pending', label: 'Pending Report', createdAt: Date.now() }
        ],
        unreadCount: 1
      };
      localStorage.setItem('wiki_edu_downloads_user1', JSON.stringify(savedData));

      const state = getInitialState('wiki_edu_downloads_user1');
      expect(state.items).toEqual(savedData.items);
      expect(state.unreadCount).toBe(1);
    });

    test('filters out downloads older than one week', () => {
      const twoWeeksAgo = Date.now() - (2 * ONE_WEEK_MS);
      const savedData = {
        items: [
          { id: 'old', status: 'ready', label: 'Old Report', createdAt: twoWeeksAgo },
          { id: 'recent', status: 'ready', label: 'Recent Report', createdAt: Date.now() }
        ],
        unreadCount: 2
      };
      localStorage.setItem('wiki_edu_downloads_user1', JSON.stringify(savedData));

      const state = getInitialState('wiki_edu_downloads_user1');
      expect(state.items.map(i => i.id)).toEqual(['recent']);
      expect(state.unreadCount).toBe(1);
    });
  });

  describe('action handling', () => {
    test('ADD_DOWNLOAD adds download to list and increments unreadCount', () => {
      const initialState = { items: [], unreadCount: 0 };
      deepFreeze(initialState);

      const download = { id: 'd1', label: 'Test Report', status: 'pending' };
      const nextState = downloads(initialState, { type: ADD_DOWNLOAD, download });

      expect(nextState.items).toEqual([download]);
      expect(nextState.unreadCount).toBe(1);
    });

    test('UPDATE_DOWNLOAD updates download attributes', () => {
      const initialState = {
        items: [{ id: 'd1', label: 'Test Report', status: 'pending' }],
        unreadCount: 1
      };
      deepFreeze(initialState);

      const nextState = downloads(initialState, {
        type: UPDATE_DOWNLOAD,
        id: 'd1',
        changes: { status: 'ready', downloadUrl: '/url/to/file.csv' }
      });

      expect(nextState.items[0].status).toBe('ready');
      expect(nextState.items[0].downloadUrl).toBe('/url/to/file.csv');
      // When transitioning from pending to ready, unreadCount increments
      expect(nextState.unreadCount).toBe(2);
    });

    test('UPDATE_DOWNLOAD does not double-increment unreadCount if already ready', () => {
      const initialState = {
        items: [{ id: 'd1', label: 'Test Report', status: 'ready' }],
        unreadCount: 1
      };
      deepFreeze(initialState);

      const nextState = downloads(initialState, {
        type: UPDATE_DOWNLOAD,
        id: 'd1',
        changes: { filename: 'custom_name.csv' }
      });

      expect(nextState.unreadCount).toBe(1);
    });

    test('REMOVE_DOWNLOAD removes item by id', () => {
      const initialState = {
        items: [
          { id: 'd1', label: 'Report 1', status: 'ready' },
          { id: 'd2', label: 'Report 2', status: 'ready' }
        ],
        unreadCount: 2
      };
      deepFreeze(initialState);

      const nextState = downloads(initialState, {
        type: REMOVE_DOWNLOAD,
        id: 'd1'
      });

      expect(nextState.items).toEqual([{ id: 'd2', label: 'Report 2', status: 'ready' }]);
    });

    test('MARK_DOWNLOADS_READ resets unreadCount to 0', () => {
      const initialState = {
        items: [{ id: 'd1', label: 'Report 1', status: 'ready' }],
        unreadCount: 3
      };
      deepFreeze(initialState);

      const nextState = downloads(initialState, {
        type: MARK_DOWNLOADS_READ
      });

      expect(nextState.unreadCount).toBe(0);
      expect(nextState.items.length).toBe(1);
    });
  });
});
