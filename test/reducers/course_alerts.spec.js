import deepFreeze from 'deep-freeze';
import reducer from '../../app/assets/javascripts/reducers/course_alerts';
import {
  RECEIVE_ONBOARDING_ALERT
} from '../../app/assets/javascripts/constants/course_alerts';
import '../testHelper';

describe('Course Alerts reducer', () => {
  let initialState;
  beforeEach(() => {
    initialState = {
      onboardingAlert: null
    };
    deepFreeze(initialState);
  });
  test('should return the initial state', () => {
    const state = reducer(undefined, { type: null });
    expect(state).toEqual(initialState);
  });
  describe('Onboarding Alert', () => {
    test('should merge the alert when received as an object', () => {
      const action = {
        type: RECEIVE_ONBOARDING_ALERT,
        data: { alerts: [{ message: 'Onboarding alert message' }] }
      };
      const state = reducer(initialState, action);
      const [alert] = action.data.alerts;
      expect(state.onboardingAlert).toEqual(alert);
    });
    test('should replace an existing alert when another is received', () => {
      const firstAction = {
        type: RECEIVE_ONBOARDING_ALERT,
        data: { alerts: [{ message: 'Alert Message One' }] }
      };
      const firstState = reducer(initialState, firstAction);
      const secondAction = {
        type: RECEIVE_ONBOARDING_ALERT,
        data: { alerts: [{ message: 'Alert Message Two' }] }
      };
      const secondState = reducer(firstState, secondAction);
      const [alert] = secondAction.data.alerts;
      expect(secondState.onboardingAlert).toEqual(alert);
    });
  });
});
