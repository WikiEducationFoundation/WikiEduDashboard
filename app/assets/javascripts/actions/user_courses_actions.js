import API from "../utils/api.js";
import { RECEIVE_USER_COURSES, API_FAIL } from "../constants";

export const fetchCoursesForUser = userId => dispatch =>
  API.fetchUserCourses(userId)
    .then(resp =>
      dispatch({ type: RECEIVE_USER_COURSES, payload: { data: resp } }))
      .catch(response => (dispatch({ type: API_FAIL, data: response })));
