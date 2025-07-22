import { RECEIVE_TRAINING_STATUS, RECEIVE_USER_TRAINING_STATUS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';


const fetchTrainingStatusPromise = async (userId, courseId) => {
  const response = await request(`/training_status.json?user_id=${userId}&course_id=${courseId}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const fetchUserTrainingStatusPromise = async (username) => {
  const response = await request(`/user_training_status.json?username=${username}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};


export const fetchUserTrainingStatus = username => (dispatch) => {
  return fetchUserTrainingStatusPromise(username)
    .then(resp => dispatch({ type: RECEIVE_USER_TRAINING_STATUS, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const fetchTrainingStatus = (userId, courseId) => (dispatch, getState) => {
  // Do not refetch status for this user if it is already in the store.
  if (getState().trainingStatus[userId]) { return; }

  return fetchTrainingStatusPromise(userId, courseId)
    .then(resp => dispatch({ type: RECEIVE_TRAINING_STATUS, data: resp, userId }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
