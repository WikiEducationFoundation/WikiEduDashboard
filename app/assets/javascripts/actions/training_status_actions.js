import { RECEIVE_TRAINING_STATUS, RECEIVE_USER_TRAINING_STATUS, API_FAIL } from '../constants';
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

const fetchUserTrainingStatusPromise = (username) => {
  return new Promise((res, rej) => {
    const url = `/user_training_status.json?username=${username}`;
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


export const fetchUserTrainingStatus = username => (dispatch) => {
  return fetchUserTrainingStatusPromise(username)
    .then(resp => dispatch({ type: RECEIVE_USER_TRAINING_STATUS, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const fetchTrainingStatus = (userId, courseId) => (dispatch) => {
  return fetchTrainingStatusPromise(userId, courseId)
    .then(resp => dispatch({ type: RECEIVE_TRAINING_STATUS, data: resp, userId }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
