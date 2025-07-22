import { BAD_WORK_ALERT_SUBMITTED, BAD_WORK_ALERT_CREATED, RESET_BAD_WORK_ALERT } from '../constants';

const initialState = { submitting: false, created: false };

export default function badWorkAlert(state = initialState, action) {
  switch (action.type) {
    case BAD_WORK_ALERT_SUBMITTED:
      return { ...state, submitting: true };
    case BAD_WORK_ALERT_CREATED:
      return { ...state, submitting: false, created: true };
    case RESET_BAD_WORK_ALERT:
      return { ...state, submitting: false, created: false };
    default:
      return state;
  }
}
