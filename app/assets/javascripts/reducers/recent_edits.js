import { RECEIVE_RECENT_EDITS } from "../constants";


const initialState = {
  revisions: [],
  loading: true
};


export default function recentEdits(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_RECENT_EDITS: {
      return {
        revisions: action.payload.data.revisions,
        loading: false
      };
    }
    default:
      return state;
  }
}
