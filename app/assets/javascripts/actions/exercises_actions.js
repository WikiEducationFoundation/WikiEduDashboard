import {
  API_FAIL,
  EXERCISE_FETCH_STARTED,
  EXERCISE_FETCH_COMPLETED
} from '../constants';
import request from '../utils/request';

export const fetchTrainingModuleExercisesByUser = (course_id, user_id) => (dispatch) => {
  dispatch({ type: EXERCISE_FETCH_STARTED });

  let url = `/training_modules_users?course_id=${course_id}`;
  if (user_id) url += `&user_id=${user_id}`;
  return request(url)
    .then(resp => resp.json())
    .then(resp => dispatch({ type: EXERCISE_FETCH_COMPLETED, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
