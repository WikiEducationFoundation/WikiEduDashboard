import { RECEIVE_CAMPAIGNS, SORT_CAMPAIGNS, DELETE_CAMPAIGN, API_FAIL, RECEIVE_ALL_CAMPAIGNS, ADD_CAMPAIGN } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import fetch from 'cross-fetch';

const fetchCampaignsPromise = (courseId) => {
  return fetch(`/courses/${courseId}/campaigns.json`, {
    credentials: 'include'
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
  return fetch(`/courses/${courseId}/campaigns.json`, {
    credentials: 'include',
    method: 'DELETE',
    body: JSON.stringify({ campaign: { title: campaignId } })
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
  return fetch(`/courses/${courseId}/campaigns.json`, {
    credentials: 'include',
    method: 'POST',
    body: JSON.stringify({ campaign: { title: campaignId } })
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
  return fetch('/lookups/campaign.json', {
    credentials: 'include'
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
