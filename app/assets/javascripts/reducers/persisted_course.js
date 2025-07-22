import {
  RECEIVE_COURSE,
  PERSISTED_COURSE
} from '../constants';

export default function persistedCourse(state = {}, action) {
  switch (action.type) {
    case RECEIVE_COURSE:
    case PERSISTED_COURSE:
      return { ...action.data.course };
    default:
      return state;
  }
}
