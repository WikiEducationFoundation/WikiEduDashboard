import API from '../utils/api.js';
import { RECEIVE_USERS, ADD_USER, REMOVE_USER, SORT_USERS, API_FAIL } from '../constants';

export const fetchUsers = courseSlug => dispatch => {
  return API.fetch(courseSlug, 'users')
    .then(data => dispatch({ type: RECEIVE_USERS, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const addUser = (courseSlug, user) => dispatch => {
  return API.modify('user', courseSlug, user, true)
    .then(data => dispatch({ type: ADD_USER, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const removeUser = (courseSlug, user) => dispatch => {
  return API.modify('user', courseSlug, user, false)
    .then(data => dispatch({ type: REMOVE_USER, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const sortUsers = key => ({ type: SORT_USERS, key });
