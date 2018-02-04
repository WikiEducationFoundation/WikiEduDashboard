import { CHAT_LOGIN_SUCCEEDED, ENABLE_CHAT_SUCCEEDED, API_FAIL, SHOW_CHAT_ON } from "../constants";

export const requestAuthToken = () => dispatch => {
  return (
      new Promise((res, rej) =>
        $.ajax({
          type: 'GET',
          url: '/chat/login.json',
          success(data) {
            return res(data);
          }
        })
        .fail((obj) => {
          logErrorMessage(obj);
          return rej(obj);
        })
      )

      .then(resp => dispatch({
        type: CHAT_LOGIN_SUCCEEDED,
        payload: {
          data: resp,
        }
      }))
      .catch(resp => dispatch({
        type: API_FAIL,
        payload: {
          data: resp
        }
      }))
    );
};

export const enableForCourse = (opts = {}) => dispatch => {
  return (
      new Promise((res, rej) =>
        $.ajax({
          type: 'PUT',
          url: `/chat/enable_for_course/${opts.courseId}.json`,
          success(data) {
            return res(data);
          }
        })
        .fail((obj) => {
          logErrorMessage(obj);
          return rej(obj);
        })
      )

      .then(resp => dispatch({
        type: ENABLE_CHAT_SUCCEEDED,
        payload: {
          data: resp
        }
      }))
      .catch(resp => dispatch({
        type: API_FAIL,
        payload: {
          data: resp
        }
      }))
    );
};

export const showChatOn = () => dispatch => {
  return (
      dispatch({
        type: SHOW_CHAT_ON,
      })
    );
};
