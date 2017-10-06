import { NEED_HELP_ALERT_SUBMITTED, NEED_HELP_ALERT_CREATED, RESET_NEED_HELP_ALERT } from '../constants';

const initialState = { submitting: false, created: false };

export default function needHelpAlert(state = initialState, action) {
  switch (action.type) {
    case NEED_HELP_ALERT_SUBMITTED:
      return { ...state, submitting: true };
    case NEED_HELP_ALERT_CREATED:
      return { ...state, submitting: false, created: true };
    case RESET_NEED_HELP_ALERT:
      return { ...state, submitting: false, created: false };
    default:
      return state;
  }
}
