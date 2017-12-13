import { RECEIVE_REVISIONS, RECEIVE_MORE_REVISIONS } from '../constants';
const initialState = 10;

export default function ui(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_REVISIONS:
      console.log(state + 1)
    case RECEIVE_MORE_REVISIONS:
      return state + 2;
    default:
      return state;
  }
}
