import { RECEIVE_TRAINING_STATUS, SORT_TRAINING_STATUS, API_FAIL } from "../constants";

export const fetchTrainingStatus = (studentId, courseId) => dispatch => {
  return (
    API.fetchTrainingStatus(studentId, courseId)
      .then(resp =>
        dispatch({
          type: RECEIVE_TRAINING_STATUS,
          payload: {
            data: resp,
          }
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortTrainingStatus = key => ({ type: SORT_TRAINING_STATUS, key: key });
