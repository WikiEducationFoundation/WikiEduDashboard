import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { useDispatch } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchCampaignAlerts, filterAlerts } from '../../actions/alert_actions';

const CampaignAlerts = () => {
  const [defaultFilters] = useState([
    { value: 'ArticlesForDeletionAlert', label: 'Articles For Deletion' },
    { value: 'DiscretionarySanctionsEditAlert', label: 'Discretionary Sanctions' }
  ]);
  const dispatch = useDispatch();

  const { campaign_slug } = useParams(); // Gets campaign slug from router params using a hook


  useEffect(() => {
    // This clears Rails parts of the previous pages, when changing Campaign tabs
    if (document.getElementById('users')) {
      document.getElementById('users').innerHTML = '';
    }
    if (document.getElementById('campaign-articles')) {
      document.getElementById('campaign-articles').innerHTML = '';
    }
    if (document.getElementById('courses')) {
      document.getElementById('courses').innerHTML = '';
    }
    if (document.getElementById('overview-campaign-details')) {
      document.getElementById('overview-campaign-details').innerHTML = '';
    }

    // This adds the specific campaign alerts to the redux state, to be used in AlertsHandler
    dispatch(fetchCampaignAlerts(campaign_slug));
    dispatch(filterAlerts(defaultFilters));
  }, []);


  return (
    <AlertsHandler
      alertLabel={I18n.t('campaign.alert_label')}
      noAlertsLabel={I18n.t('campaign.no_alerts')}
    />
  );
};

export default (CampaignAlerts);
