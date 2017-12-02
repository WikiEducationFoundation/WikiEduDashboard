import { RECEIVE_CATEGORIES, ADD_CATEGORY, DELETE_CATEGORY } from "../constants";

const initialState = {
  categories: [],
  loading: true
};

export default function categories(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_CATEGORIES:
    case ADD_CATEGORY:
    case DELETE_CATEGORY: {
      return {
        categories: action.data.course.categories,
        loading: false
      };
    }
    default:
      return state;
  }
}
