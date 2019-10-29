import {
  API_FAIL,
  EXERCISE_FETCH_STARTED,
  EXERCISE_FETCH_COMPLETED
} from '../constants';

const getCsrf = () => document.querySelector("meta[name='csrf-token']").getAttribute('content');

export const fetchTrainingModuleExercisesByUser = course_id => (dispatch) => {
  dispatch({ type: EXERCISE_FETCH_STARTED });

  return fetch(`/training_modules_users?course_id=${course_id}`, {
    credentials: 'include',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrf()
    }
  }).then(resp => resp.json())
    .then(resp => dispatch({ type: EXERCISE_FETCH_COMPLETED, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
