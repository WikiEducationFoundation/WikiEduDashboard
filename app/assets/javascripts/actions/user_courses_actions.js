import API from "../utils/api.js";
import ApiFailAction from "./api_fail_action.js";
import { RECEIVE_USER_COURSES } from "../constants";

export const fetchCoursesForUser = userId => dispatch =>
  API.fetchUserCourses(userId)
    .then(resp =>
      dispatch({ type: RECEIVE_USER_COURSES, payload: { data: resp } }))
    // TODO: The Flux stores still handle API failures, so we delegate to a
    // Flux action. Once all API_FAIL actions can be handled by Redux, we can
    // replace this with a regular action dispatch.
    .catch(resp => ApiFailAction.fail(resp));
