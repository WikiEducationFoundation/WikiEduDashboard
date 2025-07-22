import { RECEIVE_USER_COURSES } from '../constants';

const initialState = {
  userCourses: [],
  loading: true
};

export default function userCourses(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_COURSES: {
      return {
        userCourses: action.payload.data.courses,
        loading: false
      };
    }
    default:
      return state;
  }
}
