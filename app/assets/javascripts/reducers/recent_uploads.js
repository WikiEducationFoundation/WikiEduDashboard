import { RECEIVE_RECENT_UPLOADS } from "../constants";

const initialState = {
  uploads: [],
  loading: true
};

export default function recentUploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_RECENT_UPLOADS: {
      return {
        uploads: action.payload.data.uploads,
        loading: false
      };
    }
    default:
      return state;
  }
}
