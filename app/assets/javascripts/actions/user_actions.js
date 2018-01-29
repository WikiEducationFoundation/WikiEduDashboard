import API from '../utils/api.js';
import { RECEIVE_USERS, ADD_USER, REMOVE_USER, SORT_USERS, API_FAIL } from '../constants';

export const fetchUsers = courseId => dispatch => {
  return API.fetch(courseId, 'users')
    .then(data => dispatch({ type: RECEIVE_USERS, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const addUser = (courseId, user) => dispatch => {
  return API.modify('user', courseId, user, true)
    .then(data => dispatch({ type: ADD_USER, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const removeUser = (courseId, user) => dispatch => {
  return API.modify('user', courseId, user, false)
    .then(data => dispatch({ type: REMOVE_USER, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const sortUsers = key => ({ type: SORT_USERS, key });
