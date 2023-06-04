import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import AlertsHandler from './alerts_handler.jsx';
import { fetchTaggedCourseAlerts } from '../../actions/alert_actions';
import { useParams } from 'react-router-dom';

const TaggedCourseAlerts = () => {
  const { tag } = useParams();
  const dispatch = useDispatch();

  useEffect(() => dispatch(fetchTaggedCourseAlerts(tag)), []);

  return (
    <AlertsHandler
      alertLabel={I18n.t('campaign.alert_label')}
      noAlertsLabel={I18n.t('campaign.no_alerts')}
    />
  );
};

export default (TaggedCourseAlerts);
