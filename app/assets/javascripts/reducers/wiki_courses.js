import { RECEIVE_WIKI_COURSES, SORT_WIKI_COURSES } from '../constants/wiki_courses';
import { sortByKey } from '../utils/model_utils';
import { COURSE_SORT_DESCENDING } from '../utils/course_utils';

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
      const sorted = sortByKey(
        state.courses,
        action.key,
        state.sort.sortKey,
        COURSE_SORT_DESCENDING[action.key]
      );
      return {
        ...state,
        courses: sorted.newModels,
        sort: {
          sortKey: sorted.newKey,
          key: action.key
        },
      };
    }
    default:
      return state;
  }
}
