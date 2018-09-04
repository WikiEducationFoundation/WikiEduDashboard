import {
  RECEIVE_TAGS,
  RECEIVE_ALL_TAGS,
  ADD_TAG,
  REMOVE_TAG
} from '../constants';

const initialState = {
  tags: [],
  allTags: []
};

export default function tags(state = initialState, action) {
  switch (action.type) {
    case ADD_TAG:
    case REMOVE_TAG:
    case RECEIVE_TAGS: {
      const newState = {
        ...state,
        tags: action.data.course.tags
      };
      return newState;
    }
    case RECEIVE_ALL_TAGS: {
      const newState = {
        ...state,
        allTags: action.data.values
      };
      return newState;
    }
    default:
      return state;
  }
}
