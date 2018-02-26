import { RECEIVE_USER_COURSES } from "../constants";

const initialState = {
  userCourses: []
};

export default function userCourses(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_COURSES: {
      return {
        userCourses: action.payload.data.courses
      };
    }
    default:
      return state;
  }
}
