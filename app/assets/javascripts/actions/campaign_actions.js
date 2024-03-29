import { RECEIVE_COURSE_CAMPAIGNS, SORT_CAMPAIGNS_WITH_STATS, DELETE_CAMPAIGN, API_FAIL, RECEIVE_ALL_CAMPAIGNS, ADD_CAMPAIGN, RECEIVE_CAMPAIGNS_WITH_STATS, SET_FEATURED_CAMPAIGNS } from '../constants';
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
      .catch(response => (dispatch({ type: SET_FEATURED_CAMPAIGNS, data: response })))
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

const fetchFeaturedCampaigns = async (dispatch) => {
  const response = await request('/campaigns/featured_campaigns');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  const response_data = await response.json();
  const featured_campaigns = response_data.featured_campaigns;
  dispatch({ type: SET_FEATURED_CAMPAIGNS, data: response_data });
  return featured_campaigns;
};


const fetchCampaignStatisticsPromise = async (userOnly, dispatch) => {
  const featured_campaigns = await fetchFeaturedCampaigns(dispatch);
  // newest limits the fetched campaigns to the 10 most recent ones
  // it is set to false if there are featured campaigns listed
  const newest = !(featured_campaigns.length > 0);
  const response = await request(`/campaigns/statistics.json?user_only=${userOnly}&newest=${newest}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  const response_data = await response.json();
  const campaigns = filterFeaturedCampaigns(response_data, featured_campaigns);
  return { campaigns };
};


// this function returns the campaigns along with their statistics data
// if userOnly is set to true, only campaigns the user has created will be returned
export const fetchCampaignStatistics = (userOnly = false) => (dispatch) => {
  return (
    fetchCampaignStatisticsPromise(userOnly, dispatch)
      .then((data) => {
        dispatch({
          type: RECEIVE_CAMPAIGNS_WITH_STATS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
