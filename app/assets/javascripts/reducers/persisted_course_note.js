import { RECEIVE_NOTE_DETAILS, PERSISTED_COURSE_NOTE, RESET_NOTE_TO_DEFAULT } from '../constants';

export default function persistedCourseNote(state = {}, action) {
  switch (action.type) {
    case RECEIVE_NOTE_DETAILS:
    case PERSISTED_COURSE_NOTE:
      return { ...action.note };
    case RESET_NOTE_TO_DEFAULT:
        return {};
    default:
      return state;
  }
}
