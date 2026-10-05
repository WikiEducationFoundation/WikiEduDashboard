import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import {
  addDownload,
  updateDownload,
  removeDownload,
  markDownloadsRead,
  startDownload,
  resumePendingDownloads
} from '../../app/assets/javascripts/actions/download_actions';
import {
  ADD_DOWNLOAD,
  UPDATE_DOWNLOAD,
  REMOVE_DOWNLOAD,
  MARK_DOWNLOADS_READ
} from '../../app/assets/javascripts/constants';
import * as csvPollingUtils from '../../app/assets/javascripts/utils/csv_polling_utils';

const mockStore = configureMockStore([thunk]);

describe('download actions', () => {
  let store;

  beforeEach(() => {
    store = mockStore({});
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('addDownload creates ADD_DOWNLOAD action', () => {
    const download = { id: 'd1', label: 'Report' };
    expect(addDownload(download)).toEqual({
      type: ADD_DOWNLOAD,
      download
    });
  });

  test('updateDownload creates UPDATE_DOWNLOAD action', () => {
    expect(updateDownload('d1', { status: 'ready' })).toEqual({
      type: UPDATE_DOWNLOAD,
      id: 'd1',
      changes: { status: 'ready' }
    });
  });

  test('removeDownload creates REMOVE_DOWNLOAD action', () => {
    expect(removeDownload('d1')).toEqual({
      type: REMOVE_DOWNLOAD,
      id: 'd1'
    });
  });

  test('markDownloadsRead creates MARK_DOWNLOADS_READ action', () => {
    expect(markDownloadsRead()).toEqual({
      type: MARK_DOWNLOADS_READ
    });
  });

  describe('startDownload', () => {
    test('dispatches addDownload and updates status to ready on successful poll', () => {
      let capturedCallbacks;
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockImplementation((_url, callbacks) => {
        capturedCallbacks = callbacks;
        return jest.fn(); // cancel fn
      });

      store.dispatch(startDownload({
        id: 'campaign-1-courses',
        href: '/campaigns/test/courses',
        label: 'Test Campaign — Courses'
      }));

      const actions = store.getActions();
      expect(actions[0].type).toBe(ADD_DOWNLOAD);
      expect(actions[0].download.id).toBe('campaign-1-courses');
      expect(actions[0].download.status).toBe('pending');

      // Trigger onReady callback
      capturedCallbacks.onReady({
        status: 'ready',
        url: 'https://example.com/reports/campaign-courses.csv'
      });

      const updatedActions = store.getActions();
      expect(updatedActions[1]).toEqual({
        type: UPDATE_DOWNLOAD,
        id: 'campaign-1-courses',
        changes: {
          status: 'ready',
          downloadUrl: 'https://example.com/reports/campaign-courses.csv',
          filename: 'campaign-courses.csv'
        }
      });
    });

    test('dispatches updateDownload with timeout status when polling times out', () => {
      let capturedCallbacks;
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockImplementation((_url, callbacks) => {
        capturedCallbacks = callbacks;
        return jest.fn();
      });

      store.dispatch(startDownload({
        id: 'campaign-2-students',
        href: '/campaigns/test/students',
        label: 'Test Campaign — Students'
      }));

      // Trigger onError with timeout
      capturedCallbacks.onError({ reason: 'timeout' });

      const actions = store.getActions();
      expect(actions[1]).toEqual({
        type: UPDATE_DOWNLOAD,
        id: 'campaign-2-students',
        changes: { status: 'timeout' }
      });
    });

    test('dispatches updateDownload with error status when polling encounters server error', () => {
      let capturedCallbacks;
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockImplementation((_url, callbacks) => {
        capturedCallbacks = callbacks;
        return jest.fn();
      });

      store.dispatch(startDownload({
        id: 'campaign-2-students-err',
        href: '/campaigns/test/students',
        label: 'Test Campaign — Students'
      }));

      // Trigger onError with server error
      capturedCallbacks.onError({ reason: 'server', status: 500 });

      const actions = store.getActions();
      expect(actions[1]).toEqual({
        type: UPDATE_DOWNLOAD,
        id: 'campaign-2-students-err',
        changes: { status: 'error' }
      });
    });

    test('updates existing download to pending on retry instead of adding duplicate', () => {
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockReturnValue(jest.fn());
      const storeWithExisting = mockStore({
        downloads: {
          items: [{ id: 'campaign-retry', status: 'timeout', label: 'Retry Item' }]
        }
      });

      storeWithExisting.dispatch(startDownload({
        id: 'campaign-retry',
        href: '/campaigns/test/retry',
        label: 'Retry Item'
      }));

      const actions = storeWithExisting.getActions();
      expect(actions[0]).toEqual({
        type: UPDATE_DOWNLOAD,
        id: 'campaign-retry',
        changes: { status: 'pending' }
      });
    });

    test('cancels active poll when removeDownload is called', () => {
      const mockCancel = jest.fn();
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockReturnValue(mockCancel);

      store.dispatch(startDownload({
        id: 'campaign-3-instructors',
        href: '/campaigns/test/instructors',
        label: 'Test Campaign — Instructors'
      }));

      removeDownload('campaign-3-instructors');
      expect(mockCancel).toHaveBeenCalled();
    });

    test('invokes onGenerating callback only once across multiple generating events', () => {
      let capturedCallbacks;
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockImplementation((_url, callbacks) => {
        capturedCallbacks = callbacks;
        return jest.fn();
      });

      const onGenerating = jest.fn();
      store.dispatch(startDownload({
        id: 'campaign-gen-test',
        href: '/campaigns/test/gen',
        label: 'Test Campaign — Generating',
        onGenerating
      }));

      expect(onGenerating).not.toHaveBeenCalled();

      // First 202 generating event
      capturedCallbacks.onGenerating({ status: 'generating' });
      expect(onGenerating).toHaveBeenCalledTimes(1);

      // Subsequent 202 generating event should not invoke callback again
      capturedCallbacks.onGenerating({ status: 'generating' });
      expect(onGenerating).toHaveBeenCalledTimes(1);
    });

    test('does not invoke onGenerating callback when report is ready immediately', () => {
      let capturedCallbacks;
      jest.spyOn(csvPollingUtils, 'pollReportCsv').mockImplementation((_url, callbacks) => {
        capturedCallbacks = callbacks;
        return jest.fn();
      });

      const onGenerating = jest.fn();
      store.dispatch(startDownload({
        id: 'campaign-ready-immediate',
        href: '/campaigns/test/ready-now',
        label: 'Test Campaign — Ready Immediately',
        onGenerating
      }));

      capturedCallbacks.onReady({
        status: 'ready',
        url: 'https://example.com/reports/campaign-ready.csv'
      });

      expect(onGenerating).not.toHaveBeenCalled();
    });
  });

  describe('resumePendingDownloads', () => {
    test('restarts polling for pending downloads only', () => {
      const pollSpy = jest.spyOn(csvPollingUtils, 'pollReportCsv').mockReturnValue(jest.fn());
      const pending = {
        id: 'campaign-resume-pending',
        href: '/campaigns/resume/students.csv',
        label: 'Resume — Students',
        status: 'pending'
      };
      store = mockStore({
        downloads: {
          items: [
            pending,
            { id: 'campaign-resume-ready', href: '/campaigns/resume/courses.csv', status: 'ready' },
            { id: 'campaign-resume-error', href: '/campaigns/resume/articles.csv', status: 'error' }
          ],
          unreadCount: 0
        }
      });

      store.dispatch(resumePendingDownloads());

      expect(pollSpy).toHaveBeenCalledTimes(1);
      expect(pollSpy).toHaveBeenCalledWith(pending.href, expect.any(Object));
      expect(store.getActions()).toEqual([
        { type: UPDATE_DOWNLOAD, id: pending.id, changes: { status: 'pending' } }
      ]);
    });
  });
});
