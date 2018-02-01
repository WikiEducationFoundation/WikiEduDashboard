import { RECEIVE_CAMPAIGNS, SORT_CAMPAIGNS, API_FAIL } from "../constants";
import logErrorMessage from '../utils/log_error_message';

const fetchCampaignsPromise = (courseId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/campaigns.json`,
      success(data) {
        console.log('hello')
        console.log(data)
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const fetchCampaigns = (courseId) => dispatch => {
  return (
    fetchCampaignsPromise(courseId)
      .then(data => {
        console.log('hello again')
        console.log(data)
        dispatch({
          type: RECEIVE_CAMPAIGNS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortCampaigns = key => ({ type: SORT_CAMPAIGNS, key: key });
