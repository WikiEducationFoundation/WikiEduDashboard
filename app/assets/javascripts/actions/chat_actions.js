import { CHAT_LOGIN_SUCCEEDED, ENABLE_CHAT_SUCCEEDED, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import fetch from 'cross-fetch';

export const requestAuthToken = () => (dispatch) => {
  return fetch('/chat/login.json', {
    credentials: 'include'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    })
    .then(resp => dispatch({
      type: CHAT_LOGIN_SUCCEEDED,
      payload: {
        data: resp,
      }
    }))
    .catch(resp => dispatch({
      type: API_FAIL,
      data: resp
    }));
};

export const enableForCourse = (opts = {}) => (dispatch) => {
  return fetch(`/chat/enable_for_course/${opts.courseId}.json`, {
    method: 'PUT',
    credentials: 'include'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    })
    .then(resp => dispatch({
      type: ENABLE_CHAT_SUCCEEDED,
      payload: {
        data: resp
      }
    }))
    .catch(resp => dispatch({
      type: API_FAIL,
      data: resp
    }))
  ;
};
