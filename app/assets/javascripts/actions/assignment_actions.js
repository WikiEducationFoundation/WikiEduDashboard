import API from '../utils/api.js';
import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import { addNotification } from './notification_actions.js';



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

const claimAssignmentPromise = (assignment) => {
  return request(`/assignments/${assignment.id}/claim`, {
    method: 'PUT',
    body: JSON.stringify(assignment)
  })
  .then(res => res.json());
};

export const claimAssignment = (assignment, successNotification) => (dispatch) => {
  return claimAssignmentPromise(assignment)
    .then((resp) => {
      if (resp.assignment) {
        if (successNotification) { dispatch(addNotification(successNotification)); }
        dispatch({ type: types.UPDATE_ASSIGNMENT, data: resp });
      } else {
        dispatch({ type: types.API_FAIL, data: resp });
      }
    })
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

const updateSandboxUrlPromise = (assignment, newUrl) => {
  const body = {
    id: assignment.id,
    status,
    user_id: assignment.user_id,
  };
  return request(`/assignments/${assignment.id}/${newUrl}/update_sandbox_url`, {
    body: JSON.stringify(body),
    method: 'PATCH'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  }).catch((error) => {
    logErrorMessage(error);
    return error;
  });
};

export const updateSandboxUrl = (assignment, newUrl) => (dispatch) => {
  return (
    updateSandboxUrlPromise(assignment, newUrl)
      .then((resp) => {
        if (resp.assignment) {
          dispatch({
            type: types.UPDATE_ASSIGNMENT,
            data: resp
          });
        } else {
          dispatch({ type: types.API_FAIL, data: resp });
        }
      })
      .catch((error) => {
        dispatch({ type: types.API_FAIL, data: error });
    })
  );
};
