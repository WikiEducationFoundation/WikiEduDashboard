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
  it('should return the initial state', () => {
    const state = reducer(undefined, { type: null });
    expect(state).to.deep.equal(initialState);
  });
  describe('Onboarding Alert', () => {
    it('should merge the alert when received as an object', () => {
      const action = {
        type: RECEIVE_ONBOARDING_ALERT,
        data: { alerts: [{ message: 'Onboarding alert message' }] }
      };
      const state = reducer(initialState, action);
      const [alert] = action.data.alerts;
      expect(state.onboardingAlert).to.deep.equal(alert);
    });
    it('should replace an existing alert when another is received', () => {
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
      expect(secondState.onboardingAlert).to.deep.equal(alert);
    });
  });
});
