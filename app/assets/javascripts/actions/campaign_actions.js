import { RECEIVE_CAMPAIGNS, SORT_CAMPAIGNS, DELETE_CAMPAIGN, API_FAIL, RECEIVE_ALL_CAMPAIGNS, ADD_CAMPAIGN } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const fetchCampaignsPromise = async (courseId) => {
  const response = await request(`/courses/${courseId}/campaigns.json`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw new Error(data.message);
  }
  return response.json();
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

const removeCampaignsPromise = async (courseId, campaignId) => {
  const response = await request(`/courses/${courseId}/campaign.json`, {
    method: 'DELETE',
    body: JSON.stringify({ campaign: { title: campaignId } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw new Error(data.message);
  }
  return response.json();
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

const addCampaignsPromise = async (courseId, campaignId) => {
  const response = await request(`/courses/${courseId}/campaign.json`, {
    method: 'POST',
    body: JSON.stringify({ campaign: { title: campaignId } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw new Error(data.message);
  }
  return response.json();
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

const fetchAllCampaignsPromise = async () => {
  const response = await request('/lookups/campaign.json');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw new Error(data.message);
  }
  return response.json();
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
