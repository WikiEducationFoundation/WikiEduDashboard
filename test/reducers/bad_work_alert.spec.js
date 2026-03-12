import deepFreeze from 'deep-freeze';
import badWorkAlert from '../../app/assets/javascripts/reducers/bad_work_alert';
import {
  BAD_WORK_ALERT_SUBMITTED,
  BAD_WORK_ALERT_CREATED,
  RESET_BAD_WORK_ALERT
} from '../../app/assets/javascripts/constants';
import '../testHelper';

const initialState = {
  submitting: false,
  created: false
};

describe('bad_work_alert reducer', () => {
  test('should return the initial state', () => {
    expect(badWorkAlert(undefined, {})).toEqual(initialState);
  });

  test('should set submitting to true on BAD_WORK_ALERT_SUBMITTED', () => {
    deepFreeze(initialState);
    const action = { type: BAD_WORK_ALERT_SUBMITTED };
    const newState = badWorkAlert(initialState, action);
    expect(newState).toEqual({ submitting: true, created: false });
  });

  test('should set created to true and submitting to false on BAD_WORK_ALERT_CREATED', () => {
    const submittingState = { submitting: true, created: false };
    deepFreeze(submittingState);
    const action = { type: BAD_WORK_ALERT_CREATED };
    const newState = badWorkAlert(submittingState, action);
    expect(newState).toEqual({ submitting: false, created: true });
  });

  test('should reset submitting and created on RESET_BAD_WORK_ALERT', () => {
    const createdState = { submitting: false, created: true };
    deepFreeze(createdState);
    const action = { type: RESET_BAD_WORK_ALERT };
    const newState = badWorkAlert(createdState, action);
    expect(newState).toEqual({ submitting: false, created: false });
  });

  test('should return the current state for unknown action types', () => {
    deepFreeze(initialState);
    const action = { type: 'UNKNOWN_ACTION' };
    const newState = badWorkAlert(initialState, action);
    expect(newState).toEqual(initialState);
  });
});
