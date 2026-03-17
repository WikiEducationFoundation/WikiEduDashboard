import deepFreeze from 'deep-freeze';
import needHelpAlert from '../../app/assets/javascripts/reducers/need_help_alert';
import {
  NEED_HELP_ALERT_SUBMITTED,
  NEED_HELP_ALERT_CREATED,
  RESET_NEED_HELP_ALERT
} from '../../app/assets/javascripts/constants';
import '../testHelper';

const initialState = {
  submitting: false,
  created: false
};

describe('need_help_alert reducer', () => {
  test('should return the initial state', () => {
    expect(needHelpAlert(undefined, {})).toEqual(initialState);
  });

  test('should set submitting to true on NEED_HELP_ALERT_SUBMITTED', () => {
    deepFreeze(initialState);
    const action = { type: NEED_HELP_ALERT_SUBMITTED };
    const newState = needHelpAlert(initialState, action);
    expect(newState).toEqual({ submitting: true, created: false });
  });

  test('should set created to true and submitting to false on NEED_HELP_ALERT_CREATED', () => {
    const submittingState = { submitting: true, created: false };
    deepFreeze(submittingState);
    const action = { type: NEED_HELP_ALERT_CREATED };
    const newState = needHelpAlert(submittingState, action);
    expect(newState).toEqual({ submitting: false, created: true });
  });

  test('should reset submitting and created on RESET_NEED_HELP_ALERT', () => {
    const createdState = { submitting: false, created: true };
    deepFreeze(createdState);
    const action = { type: RESET_NEED_HELP_ALERT };
    const newState = needHelpAlert(createdState, action);
    expect(newState).toEqual({ submitting: false, created: false });
  });

  test('should return the current state for unknown action types', () => {
    deepFreeze(initialState);
    const action = { type: 'UNKNOWN_ACTION' };
    const newState = needHelpAlert(initialState, action);
    expect(newState).toEqual(initialState);
  });
});
