import { RECEIVE_DYK } from "../constants";

const initialState = {
  articles: [],
  loading: true
};

export default function didYouKnow(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_DYK: {
      return {
        articles: action.payload.data.articles,
        loading: false
      };
    }
    default:
      return state;
  }
}
