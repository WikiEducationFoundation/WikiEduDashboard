import { RECEIVE_WIKI_COURSES, SORT_WIKI_COURSES } from '../constants/wiki_courses';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  isLoaded: false,
  courses: [],
  sort: {
    key: null,
    sortKey: null,
  },
};

export default function wiki_courses(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_WIKI_COURSES: {
      return {
        ...state,
        isLoaded: true,
        courses: action.data.courses
      };
    }
    case SORT_WIKI_COURSES: {
      const desc = action.key === state.sort.sortKey;
      const newCourses = sortByKey(state.courses, action.key, null, desc);
      return {
        ...state,
        courses: newCourses.newModels,
        sort: {
          sortKey: desc ? null : action.key,
          key: action.key
        },
      };
    }
    default:
      return state;
  }
}
