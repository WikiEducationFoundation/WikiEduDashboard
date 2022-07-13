import {
  RECEIVE_ACTIVE_COURSES,
  SORT_ACTIVE_COURSES,
  RECEIVE_CAMPAIGN_ACTIVE_COURSES
} from '../constants/active_courses';
import { sortByKey } from '../utils/model_utils';
import { COURSE_SORT_DESCENDING } from '../utils/course_utils';

const initialState = {
  sort: {
    key: null,
    sortKey: null,
  },
  courses: [],
  isLoaded: false,
};


export default function active_courses(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ACTIVE_COURSES:
    case RECEIVE_CAMPAIGN_ACTIVE_COURSES: {
      return {
        ...state,
        courses: action.data.courses,
        isLoaded: true,
      };
    }
    case SORT_ACTIVE_COURSES: {
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
