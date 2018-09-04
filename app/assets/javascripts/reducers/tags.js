import {
  RECEIVE_TAGS
} from '../constants';

const initialState = {
  tags: []
};

export default function tags(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_TAGS: {
      const newState = {
        ...state,
        tags: action.data.course.tags
      };
      return newState;
    }
    default:
      return state;
  }
}
