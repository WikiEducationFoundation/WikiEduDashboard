import {
  RECEIVE_ONBOARDING_ALERT
} from '../constants/course_alerts';

const initialState = {
  onboardingAlert: null
};

export default function courseAlerts(state = initialState, { type, data }) {
  switch (type) {
    case RECEIVE_ONBOARDING_ALERT: {
      const [alert] = data.alerts;
      return { ...state, onboardingAlert: alert };
    }
    default:
      return state;
  }
}
