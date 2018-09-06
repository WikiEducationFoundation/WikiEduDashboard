import { RECEIVE_TRAINING_STATUS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchTrainingStatusPromise = (userId, courseId) => {
  return new Promise((res, rej) => {
    const url = `/training_status.json?user_id=${userId}&course_id=${courseId}`;
    return $.ajax({
      type: 'GET',
      url,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const fetchTrainingStatus = (userId, courseId) => dispatch => {
  return fetchTrainingStatusPromise(userId, courseId)
    .then(resp => dispatch({ type: RECEIVE_TRAINING_STATUS, data: resp, userId }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
