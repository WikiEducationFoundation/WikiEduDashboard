import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchAssignmentsPromise = (courseId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/assignments.json`,
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

export const fetchAssignments = (courseId) => (dispatch) => {
  return (
    fetchAssignmentsPromise(courseId)
      .then(resp => {
        dispatch({
          type: types.RECEIVE_ASSIGNMENTS,
          data: resp
        });
      })
      .catch(response => dispatch({ type: types.API_FAIL, data: response }))
  );
};

export const addAssignment = assignment => ({
  type: types.ADD_ASSIGNMENT,
  data: {
    user_id: assignment.user_id,
    article_title: assignment.title,
    language: assignment.language,
    project: assignment.project,
    role: assignment.role,
    article_url: assignment.article_url,
    id: Date.now() // placeholder value to serve as React key
  }
});

export const deleteAssignment = assignment => ({
  type: types.DELETE_ASSIGNMENT,
  assignmentId: assignment.id
});
