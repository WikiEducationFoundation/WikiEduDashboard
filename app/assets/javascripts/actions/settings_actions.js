
import {
  SET_ADMIN_USERS, SET_SPECIAL_USERS,
  SUBMITTING_NEW_SPECIAL_USER, REVOKING_SPECIAL_USER,
  SUBMITTING_NEW_ADMIN, REVOKING_ADMIN, SET_COURSE_CREATION_SETTINGS,
  SET_DEFAULT_CAMPAIGN, SET_FEATURED_CAMPAIGNS, REMOVE_FEATURED_CAMPAIGN,
  ADD_FEATURED_CAMPAIGN, SET_SITE_NOTICE
} from '../constants/settings.js';
import { API_FAIL } from '../constants/api';
import { ADD_NOTIFICATION } from '../constants/notifications';
import { addNotification } from '../actions/notification_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const fetchAdminUsersPromise = async () => {
  const response = await request('/settings/all_admins');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const fetchSpecialUsersPromise = async () => {
  const response = await request('/settings/special_users');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

/*
  generate promise to either upgrade or demote admin
  username(string)
  upgrade(bool): if the user is being upgraded. If false, user is demoted.
*/
const grantAdminPromise = async (username, upgrade) => {
  const url = `/settings/${upgrade ? 'upgrade' : 'downgrade'}_admin`;
  const response = await request(url, {
    method: 'POST',
    body: JSON.stringify({ user: { username } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const grantSpecialUserPromise = async (username, upgrade, position) => {
  const url = `/settings/${upgrade ? 'upgrade' : 'downgrade'}_special_user`;
  const response = await request(url, {
    method: 'POST',
    body: JSON.stringify({ special_user: { username, position } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export function fetchSpecialUsers() {
  return (dispatch) => {
    return fetchSpecialUsersPromise()
      .then((resp) => {
        dispatch({
          type: SET_SPECIAL_USERS,
          data: resp,
        });
      })
      .catch((response) => {
        dispatch({ type: API_FAIL, data: response });
      });
  };
}

export function fetchAdminUsers() {
  return (dispatch) => {
    return fetchAdminUsersPromise()
      .then((resp) => {
        dispatch({
          type: SET_ADMIN_USERS,
          data: resp,
        });
      })
      .catch((response) => {
        dispatch({ type: API_FAIL, data: response });
      });
  };
}

export const upgradeSpecialUser = (username, position) => (dispatch) => {
  // grant a user admin status
  // username: user's username
  dispatch({
    type: SUBMITTING_NEW_SPECIAL_USER,
    data: {
      submitting: true,
    },
  });

  return grantSpecialUserPromise(username, true, position)
    .then(() => {
      dispatch({
        type: SUBMITTING_NEW_SPECIAL_USER,
        data: {
          submitting: false
        },
      });
      dispatch(addNotification({
        type: 'success',
        message: `${username} was upgraded to ${position}.`,
        closable: true
      })
      );

      fetchSpecialUsersPromise()
        .then(resp =>
          dispatch({
            type: SET_SPECIAL_USERS,
            data: resp,
          }))
        .catch(err => (dispatch({ type: API_FAIL, data: err })));
    }).catch((response) => {
      dispatch({
        type: SUBMITTING_NEW_SPECIAL_USER,
        data: {
          submitting: false
        },
      });
      dispatch({
        type: API_FAIL,
        data: response,
      });
    });
};

export const downgradeSpecialUser = (username, position) => (dispatch) => {
  // remove a user's admin status
  // username: user's username
  dispatch({
    type: REVOKING_SPECIAL_USER,
    data: {
      revoking: {
        status: true,
        username,
      },
    },
  });

  return grantSpecialUserPromise(username, false, position)
    .then(() => {
      dispatch(addNotification({
        type: 'success',
        message: `${username} was removed as ${position}.`,
        closable: true
      })
      );

      fetchSpecialUsersPromise()
        .then((resp) => {
          dispatch({
            type: SET_SPECIAL_USERS,
            data: resp,
          });

          dispatch({
            type: REVOKING_SPECIAL_USER,
            data: {
              revoking: {
                status: false,
                username,
              },
            },
          });
        }).catch(
          response => (dispatch({ type: API_FAIL, data: response }))
        );
    }).catch((response) => {
      dispatch({
        type: SUBMITTING_NEW_SPECIAL_USER,
        data: {
          submitting: false
        },
      });

      if (response.responseJSON === undefined) {
        response.responseJSON = { message: response.responseText };
      }
      dispatch({
        type: API_FAIL,
        data: response,
      });
    });
};


export const upgradeAdmin = username => (dispatch) => {
  // grant a user admin status
  // username: user's username
  dispatch({
    type: SUBMITTING_NEW_ADMIN,
    data: {
      submitting: true,
    },
  });

  return grantAdminPromise(username, true)
    .then(() => {
      dispatch({
        type: SUBMITTING_NEW_ADMIN,
        data: {
          submitting: false
        },
      });
      dispatch(addNotification({
        type: 'success',
        message: `${username} was upgraded to administrator.`,
        closable: true
      }));

      fetchAdminUsersPromise()
        .then((resp) => {
          dispatch({
            type: SET_ADMIN_USERS,
            data: resp,
          });
        })
        .catch((response) => { dispatch({ type: API_FAIL, data: response }); });
    }).catch((response) => {
      dispatch({
        type: SUBMITTING_NEW_ADMIN,
        data: {
          submitting: false
        },
      });
      if (response.responseJSON === undefined) {
        response.responseJSON = { message: response.responseText };
      }
      dispatch({
        type: API_FAIL,
        data: response,
      });
    });
};

export const downgradeAdmin = username => (dispatch) => {
  // remove a user's admin status
  // username: user's username
  dispatch({
    type: REVOKING_ADMIN,
    data: {
      revoking: {
        status: true,
        username,
      },
    },
  });

  return grantAdminPromise(username, false)
    .then(() => {
      dispatch(addNotification({
        type: 'success',
        message: `${username} was removed as an administrator.`,
        closable: true
      })
      );

      fetchAdminUsersPromise()
        .then((resp) => {
          dispatch({
            type: SET_ADMIN_USERS,
            data: resp,
          });

          dispatch({
            type: REVOKING_ADMIN,
            data: {
              revoking: {
                status: false,
                username,
              },
            },
          });
        }).catch(
          response => (dispatch({ type: API_FAIL, data: response }))
        );
    }).catch((response) => {
      dispatch({
        type: SUBMITTING_NEW_ADMIN,
        data: {
          submitting: false
        },
      });

      dispatch({
        type: API_FAIL,
        data: response,
      });
    });
};


const updateSalesforceCredentialsPromise = async (password, token) => {
  const response = await request('/settings/update_salesforce_credentials', {
    method: 'POST',
    body: JSON.stringify({ password, token })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const updateSalesforceCredentials = (password, token) => (dispatch) => {
  return updateSalesforceCredentialsPromise(password, token)
    .then(data => dispatch({ type: ADD_NOTIFICATION, notification: { ...data, type: 'success', closable: true } }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

const fetchCourseCreationSettingsPromise = async () => {
  const response = await request('/settings/course_creation');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export function fetchCourseCreationSettings() {
  return (dispatch) => {
    return fetchCourseCreationSettingsPromise()
      .then((resp) => {
        dispatch({
          type: SET_COURSE_CREATION_SETTINGS,
          data: resp,
        });
      })
      .catch((response) => {
        dispatch({ type: API_FAIL, data: response });
      });
  };
}

const updateCourseCreationSettingsPromise = async (settings) => {
  const response = await request('/settings/update_course_creation', {
    method: 'POST',
    body: JSON.stringify(settings)
  });

  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const updateCourseCreationSettings = settings => (dispatch) => {
  return updateCourseCreationSettingsPromise(settings)
    .then((data) => {
      dispatch({ type: ADD_NOTIFICATION, notification: { ...data, type: 'success', closable: true } });
      fetchCourseCreationSettings()(dispatch);
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};


const fetchDefaultCamapignPromise = async () => {
  const response = await request('/settings/default_campaign');

  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export function fetchDefaultCampaign() {
  return (dispatch) => {
    return fetchDefaultCamapignPromise()
      .then((resp) => {
        dispatch({
          type: SET_DEFAULT_CAMPAIGN,
          data: resp,
        });
      })
      .catch((response) => {
        dispatch({ type: API_FAIL, data: response });
      });
  };
}

const updateDefaultCampaignPromise = async (campaignSlug) => {
  const response = await request('/settings/update_default_campaign', {
    method: 'POST',
    body: JSON.stringify({ default_campaign: campaignSlug })
  });

  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const updateDefaultCampaign = campaignSlug => (dispatch) => {
  return updateDefaultCampaignPromise(campaignSlug)
    .then((data) => {
      dispatch({ type: ADD_NOTIFICATION, notification: { ...data, type: 'success', closable: true } });
      fetchDefaultCampaign()(dispatch);
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};

const updateImpactStatsPromise = async (impactStats) => {
  const body = {
    impactStats,
  };
  const response = await request('/settings/update_impact_stats', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const updateImpactStats = impactStats => (dispatch) => {
  return updateImpactStatsPromise(impactStats)
    .then(data => dispatch({ type: ADD_NOTIFICATION, notification: { ...data, type: 'success', closable: true } }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

const fetchFeaturedCampaignsPromise = async () => {
  const response = await request('/campaigns/featured_campaigns');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export function fetchFeaturedCampaigns() {
  return (dispatch) => {
    return fetchFeaturedCampaignsPromise()
      .then((resp) => {
        dispatch({
          type: SET_FEATURED_CAMPAIGNS,
          data: resp,
        });
      })
      .catch((response) => {
        dispatch({ type: API_FAIL, data: response });
      });
  };
}

const removeFeaturedCampaignPromise = async (campaign_slug) => {
  const response = await request(`/settings/remove_featured_campaign?featured_campaign_slug=${campaign_slug}`, {
    method: 'POST'
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const updateSiteNoticePromise = async (siteNotice) => {
  const body = {
    site_notice: siteNotice,
  };
  const response = await request('/settings/update_site_notice', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const removeFeaturedCampaign = campaign_slug => (dispatch) => {
  return removeFeaturedCampaignPromise(campaign_slug)
    .then(data => dispatch({ type: REMOVE_FEATURED_CAMPAIGN, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

const addFeaturedCampaignPromise = async (campaign_slug) => {
  const response = await request(`/settings/add_featured_campaign?featured_campaign_slug=${campaign_slug}`, {
    method: 'POST'
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const getSiteNoticePromise = async () => {
  const response = await request('/settings/fetch_site_notice', {
    method: 'GET'
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const getSiteNotice = () => (dispatch) => {
  return getSiteNoticePromise()
    .then((resp) => {
      if (Object.keys(resp.site_notice).length !== 0) {
        dispatch({
          type: SET_SITE_NOTICE,
          data: resp,
        });
      }
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const updateSiteNotice = siteNotice => (dispatch) => {
  return updateSiteNoticePromise(siteNotice)
    .then((data) => {
      dispatch({
        type: ADD_NOTIFICATION,
        notification: { ...data, type: 'success', closable: true }
      });
      dispatch(getSiteNotice());
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const addFeaturedCampaign = campaign_slug => (dispatch) => {
  return addFeaturedCampaignPromise(campaign_slug)
    .then(data => dispatch({ type: ADD_FEATURED_CAMPAIGN, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};
