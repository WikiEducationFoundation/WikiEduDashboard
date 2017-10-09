import API from "../utils/api.js";
import { RECEIVE_USER_COURSES } from "../constants";

export const fetchCoursesForUser = userId => {
  return API.fetchUserCourses(userId)
    .then(resp => ({ actionType: RECEIVE_USER_COURSES, data: resp }))
    .catch(resp => ({ actionType: "API_FAIL", data: resp }));
};
