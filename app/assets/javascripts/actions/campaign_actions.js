import { RECEIVE_CAMPAIGNS, SORT_CAMPAIGNS, DELETE_CAMPAIGN, API_FAIL, RECEIVE_ALL_CAMPAIGNS, ADD_CAMPAIGN } from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchCampaignsPromise = (courseId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/campaigns.json`,
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

export const fetchCampaigns = courseId => (dispatch) => {
  return (
    fetchCampaignsPromise(courseId)
      .then((data) => {
        dispatch({
          type: RECEIVE_CAMPAIGNS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortCampaigns = key => ({ type: SORT_CAMPAIGNS, key: key });

const removeCampaignsPromise = (courseId, campaignId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'DELETE',
      url: `/courses/${courseId}/campaign.json`,
      data: { campaign: { title: campaignId } },
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

export const removeCampaign = (courseId, campaignId) => (dispatch) => {
  return (
    removeCampaignsPromise(courseId, campaignId)
      .then((data) => {
        dispatch({
          type: DELETE_CAMPAIGN,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

const addCampaignsPromise = (courseId, campaignId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'POST',
      url: `/courses/${courseId}/campaign.json`,
      data: { campaign: { title: campaignId } },
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

export const addCampaign = (courseId, campaignId) => (dispatch) => {
  return (
    addCampaignsPromise(courseId, campaignId)
      .then((data) => {
        dispatch({
          type: ADD_CAMPAIGN,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

const fetchAllCampaignsPromise = () => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: '/lookups/campaign.json',
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

export const fetchAllCampaigns = () => (dispatch) => {
  return (
    fetchAllCampaignsPromise()
      .then((data) => {
        dispatch({
          type: RECEIVE_ALL_CAMPAIGNS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
