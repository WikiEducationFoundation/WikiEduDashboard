import deepFreeze from 'deep-freeze';
import notifications from '../../app/assets/javascripts/reducers/notifications';
import { ADD_NOTIFICATION, REMOVE_NOTIFICATION, API_FAIL, SAVE_TIMELINE_FAIL } from '../../app/assets/javascripts/constants';

describe('notifications reducer', () => {
  let errorNotification1;
  let errorNotification2;
  let errorNotification3;
  let successNotification1;
  beforeEach(() => {
    errorNotification1 = {
    type: 'error',
    message: 'Notification 1'
    };
  errorNotification2 = {
    type: 'error',
    message: 'Notification 2'
    };
  errorNotification3 = {
    type: 'error',
    message: 'Notification 3'
    };
  successNotification1 = {
    type: 'success',
    message: 'Notification 1'
    };
  });

  it('should return the initial state', () => {
    expect(notifications(undefined, {})).toEqual([]);
  });

  it('should handle ADD_NOTIFICATION when notifications < max', () => {
    const initialState = [errorNotification1, errorNotification2, errorNotification3];
    const action = {
      type: ADD_NOTIFICATION,
      notification: successNotification1
    };
    const expectedState = [...initialState, successNotification1];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle ADD_NOTIFICATION when notifications == max', () => {
    const initialState = [errorNotification2, errorNotification1, errorNotification3];
    const errorNotification4 = {
      type: 'error',
      message: 'Notification 4'
    };
    const action = {
      type: ADD_NOTIFICATION,
      notification: errorNotification4
    };
    const expectedState = [errorNotification1, errorNotification3, errorNotification4];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle REMOVE_NOTIFICATION', () => {
    const expectedState = [errorNotification1, successNotification1, errorNotification3];
    const initialState = [...expectedState, errorNotification2];
    const action = {
      type: REMOVE_NOTIFICATION,
      notification: errorNotification2
    };
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle API_FAIL for readyState 0', () => {
    const initialState = [errorNotification2, successNotification1];
    const action = {
      type: API_FAIL,
      data: {
        readyState: 0
      }
    };
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(initialState);
  });

  it('should handle API_FAIL for silent action', () => {
    const initialState = [errorNotification2, successNotification1];
    const action = {
      type: API_FAIL,
      silent: true,
      data: {
        errors: 'Example notification error message'
      }
    };
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(initialState);
  });

  it('should handle API_FAIL for already saved notification', () => {
    const notification = {
      closable: true,
      type: 'error',
      message: 'Example notification status'
    };
    const initialState = [notification];
    const action = {
      type: API_FAIL,
      data: {
        statusText: 'Example notification status'
      }
    };
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(initialState);
  });

  it('should handle API_FAIL for action with valid data.responseText', () => {
    const initialState = [];
    const action = {
      type: API_FAIL,
      data: {
        responseText: '{"message": "Example notification status"}'
      }
    };
    const notification = {
      closable: true,
      type: 'error',
      message: 'Example notification status'
    };
    const expectedState = [notification];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle API_FAIL for action with invalid data.responseText', () => {
    const initialState = [];
    const action = {
      type: API_FAIL,
      data: {
        responseText: '{"message":"Example notification status"'
      }
    };
    // when data.responseText is invalid, notification.message is assigned
    // the data object as the last fallback. This is however serialized into
    // a string as React cannot render objects.
    const notification = {
      closable: true,
      type: 'error',
      message: '{\"responseText\":\"{\\\"message\\\":\\\"Example notification status\\\"\"}'
    };
    const expectedState = [notification];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle API_FAIL for action with data.responseJSON.error', () => {
    const initialState = [];
    const action = {
      type: API_FAIL,
      data: {
        responseJSON: {
          error: 'Example notification status'
        }
      }
    };
    const notification = {
      closable: true,
      type: 'error',
      message: 'Example notification status'
    };
    const expectedState = [notification];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle API_FAIL for action with failed JSONP request', () => {
    const initialState = [];
    const action = {
      type: API_FAIL,
      data: {
        message: 'JSONP request failed'
      }
    };
    const notification = {
      closable: true,
      type: 'error',
      message: I18n.t('customize_error_message.JSONP_request_failed')
    };
    const expectedState = [notification];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle API_FAIL for action with empty data', () => {
    const initialState = [];
    const notification = {
      closable: true,
      type: 'error',
      message: ''
    };
    const action = {
      type: API_FAIL,
      data: ''
    };
    const expectedState = [notification];
    const errorSpy = jest.spyOn(console, 'error');
    const logSpy = jest.spyOn(console, 'log');
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
    expect(errorSpy).toHaveBeenCalledWith('Error: ', '');
    expect(logSpy).toHaveBeenCalledWith('');
  });

  it('should handle SAVE_TIMELINE_FAIL', () => {
    const initialState = [errorNotification2, successNotification1];
    deepFreeze(initialState);
    const action = {
      type: SAVE_TIMELINE_FAIL,
      data: {},
      courseSlug: {}
    };
    const notification = {
      closable: true,
      type: 'error',
      message: 'The changes you just submitted were not saved. '
              + 'This may happen if the timeline has been changed — '
              + 'by someone else, or by you in another browser '
              + 'window — since the page was loaded. The latest '
              + 'course data has been reloaded, and is ready for '
              + 'you to edit further.'
    };
    const expectedState = [...initialState, notification];
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle unknown action type', () => {
    const initialState = [errorNotification2, successNotification1];
    deepFreeze(initialState);
    const action = {
      type: 'UNKNOWN_ACTION'
    };
    deepFreeze(initialState);
    expect(notifications(initialState, action)).toEqual(initialState);
  });
});
