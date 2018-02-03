import { CHAT_LOGIN_SUCCEEDED, ENABLE_CHAT_SUCCEEDED, API_FAIL, SHOW_CHAT_ON } from "../constants";
import API from "../utils/api.js";

export const requestAuthToken = (opts = {}) => dispatch => {
  return (
      API.chatLogin()
      .then(resp => dispatch({
        type: CHAT_LOGIN_SUCCEEDED,
        payload: {
          data: resp,
        }
      }));
      .catch(resp => dispatch({
        type: API_FAIL,
        payload: {
          data: resp
        }
      }));
    );
};

export const enableForCourse = (opts = {}) => dispatch => {
  return (
      API.enableChat(opts.courseId)
      .then(resp => dispatch({
        type: ENABLE_CHAT_SUCCEEDED,
        payload: {
          data: resp
        }
      }));
      .catch(resp => dispatch({
        type: API_FAIL,
        payload:{
          data: resp
        }
      }));
    );
};

export const showChatOn = (opts = {}) => dispatch => {
  return (
      dispatch({
        type: SHOW_CHAT_ON,
      });
    );
};
