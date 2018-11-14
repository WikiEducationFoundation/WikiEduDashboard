import { RECEIVE_USER_REVISIONS } from '../constants';

const initialState = {};

export default function userRevisions(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_REVISIONS: {
      return {
        ...state,
        [action.userId]: action.data.course.revisions
      };
    }
    default:
      return state;
  }
}
