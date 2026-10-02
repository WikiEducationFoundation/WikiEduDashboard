import { ENTER_STUDENT_VIEW, EXIT_STUDENT_VIEW } from '../constants';

export default function viewAsStudent(state = false, action) {
  switch (action.type) {
    case ENTER_STUDENT_VIEW:
      return true;
    case EXIT_STUDENT_VIEW:
      return false;
    default:
      return state;
  }
}
