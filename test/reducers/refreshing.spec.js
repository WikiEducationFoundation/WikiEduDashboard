import deepFreeze from 'deep-freeze';
import refreshing from '../../app/assets/javascripts/reducers/refreshing';
import { REFRESHING_DATA, DONE_REFRESHING_DATA } from '../../app/assets/javascripts/constants';
import '../testHelper';

// Initial state for the refreshing reducer
const initialState = {
  refreshing: false
};

describe('refreshing reducer', () => {
  // Test that the reducer returns the initial state when called with undefined
  test('should return the initial state', () => {
    expect(refreshing(undefined, {})).toEqual(initialState);
  });

  // Test REFRESHING_DATA action sets refreshing to true
  test('should handle REFRESHING_DATA action by setting refreshing to true', () => {
    const action = {
      type: REFRESHING_DATA
    };

    const expectedState = {
      refreshing: true
    };

    deepFreeze(initialState);
    const newState = refreshing(initialState, action);
    expect(newState).toEqual(expectedState);
  });

  // Test DONE_REFRESHING_DATA action sets refreshing back to false
  test('should handle DONE_REFRESHING_DATA action by setting refreshing to false', () => {
    // Start with a state where refreshing is true
    const currentState = {
      refreshing: true
    };

    const action = {
      type: DONE_REFRESHING_DATA
    };

    const expectedState = {
      refreshing: false
    };

    deepFreeze(currentState);
    const newState = refreshing(currentState, action);
    expect(newState).toEqual(expectedState);
  });

  // Test that unknown action types return the current state unchanged
  test('should return the current state for unknown action types', () => {
    const action = {
      type: 'UNKNOWN_ACTION'
    };

    deepFreeze(initialState);
    const newState = refreshing(initialState, action);
    expect(newState).toEqual(initialState);
  });
});

