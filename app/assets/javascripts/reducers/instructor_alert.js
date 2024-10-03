import { ALERT_INSTRUCTOR_CREATE, ALERT_INSTRUCTOR_FAILED, ALERT_INSTRUCTOR_MODAL_VISIBLE, ALERT_INSTRUCTOR_MODAL_HIDDEN, ALERT_INSTRUCTOR_UPDATE_MESSAGE, ALERT_INSTRUCTOR_UPDATE_SUBJECT } from '../constants/alert';


const initialState = {
  subject: '',
  message: '',
  status: 'DEFAULT', // DEFAULT, PENDING, FAILED, SUCCESS
  error: null,
  modal: false // modal visibility
};

const reducer = (state = initialState, action) => {
  switch (action.type) {
    case ALERT_INSTRUCTOR_UPDATE_MESSAGE:
      return {
        ...state,
        message: action.payload
      };

    case ALERT_INSTRUCTOR_UPDATE_SUBJECT:
      return {
        ...state,
        subject: action.payload
      };

    case ALERT_INSTRUCTOR_MODAL_VISIBLE:
      return {
        ...state,
        modal: true
      };

    case ALERT_INSTRUCTOR_MODAL_HIDDEN:
      return initialState;

    case ALERT_INSTRUCTOR_CREATE:
      return {
        ...state,
        status: 'PENDING'
      };

    case ALERT_INSTRUCTOR_FAILED:
      return {
        ...state,
        status: 'FAILED',
        error: action.payload
      };

    default:
      return state;
  }
};

export default reducer;
