import API from '../utils/api.js';
import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const fetchAssignmentsPromise = (courseSlug) => {
  return request(`/courses/${courseSlug}/assignments.json`)
    .then((res) => {
      if (res.ok && res.status === 200) {
        return res.json();
      }
      return Promise.reject(res);
    })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

export const fetchAssignments = courseSlug => (dispatch) => {
  return (
    fetchAssignmentsPromise(courseSlug)
      .then((resp) => {
        dispatch({
          type: types.RECEIVE_ASSIGNMENTS,
          data: resp
        });
      })
      .catch(response => dispatch({ type: types.API_FAIL, data: response }))
  );
};

export const addAssignment = assignment => (dispatch) => {
  return API.createAssignment(assignment)
    .then(resp => dispatch({ type: types.ADD_ASSIGNMENT, data: resp }))
    .catch(response => dispatch({ type: types.API_FAIL, data: response }));
};

export const randomPeerAssignments = randomAssignments => (dispatch) => {
  dispatch({ type: types.LOADING_ASSIGNMENTS });
  return API.createRandomPeerAssignments(randomAssignments)
    .then(resp => dispatch({ type: types.RECEIVE_ASSIGNMENTS, data: resp }))
    .catch(response => dispatch({ type: types.API_FAIL, data: response }));
};

export const deleteAssignment = assignment => (dispatch) => {
  return API.deleteAssignment(assignment)
    .then(resp => dispatch({ type: types.DELETE_ASSIGNMENT, data: resp }))
    .catch(response => dispatch({ type: types.API_FAIL, data: response }));
};

export const claimAssignment = assignment => (dispatch) => {
  return API.updateAssignment(assignment)
    .then(resp => dispatch({ type: types.UPDATE_ASSIGNMENT, data: resp }))
    .catch(response => dispatch({ type: types.API_FAIL, data: response }));
};

export const updateAssignmentStatus = (assignment, status) => () => {
  const body = {
    id: assignment.id,
    status,
    user_id: assignment.user_id
  };
  return request(`/assignments/${assignment.id}/status.json`, {
    body: JSON.stringify(body),
    method: 'PATCH'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};
