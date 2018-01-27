import { RECEIVE_SUSPECTED_PLAGIARISM } from "../constants";


const initialState = {
  revisions: [],
  loading: true
};


export default function suspectedPlagiarism(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_SUSPECTED_PLAGIARISM: {
      return {
        revisions: action.payload.data.revisions,
        loading: false
      };
    }
    default:
      return state;
  }
}
