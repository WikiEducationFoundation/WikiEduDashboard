import { RECEIVE_COURSE_CAMPAIGNS, SORT_CAMPAIGNS_WITH_STATS, DELETE_CAMPAIGN, API_FAIL, RECEIVE_ALL_CAMPAIGNS, ADD_CAMPAIGN, RECEIVE_CAMPAIGNS_WITH_STATS } from '../constants';
import filterFeaturedCampaigns from '../utils/filter_featured_campaigns';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const fetchCampaignsPromise = async (courseId) => {
  const response = await request(`/courses/${courseId}/campaigns.json`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
      response.responseText = data;
      throw response;
  }
  return response.json();
};

export const fetchCampaigns = courseId => (dispatch) => {
  return (
    fetchCampaignsPromise(courseId)
      .then((data) => {
        dispatch({
          type: RECEIVE_COURSE_CAMPAIGNS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortCampaigns = key => ({ type: SORT_CAMPAIGNS_WITH_STATS, key: key });

const removeCampaignsPromise = async (courseId, campaignId) => {
  const response = await request(`/courses/${courseId}/campaign.json`, {
    method: 'DELETE',
    body: JSON.stringify({ campaign: { title: campaignId } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
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
    const data = await response.text();
    response.responseText = data;
    throw response;
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
    const data = await response.text();
    response.responseText = data;
    throw response;
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

const fetchFeaturedCampaigns = async () => {
  const response = await request('/campaigns/featured_campaigns?only_slug=true');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const fetchCampaignStatisticsPromise = async (userOnly, newest) => {
  const featured_campaigns = await fetchFeaturedCampaigns();
  const response = await request(`/campaigns/statistics.json?user_only=${userOnly}&newest=${newest}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  const response_json = await response.json();
  const campaigns = filterFeaturedCampaigns(response_json, featured_campaigns);
  return { campaigns };
};


// this function returns the campaigns along with their statistics data
// if userOnly is set to true, only campaigns the user has created will be returned
// newest limits the campaigns to the 10 most recent ones
export const fetchCampaignStatistics = (userOnly = false, newest = false) => (dispatch) => {
  return (
    fetchCampaignStatisticsPromise(userOnly, newest)
      .then((data) => {
        dispatch({
          type: RECEIVE_CAMPAIGNS_WITH_STATS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
