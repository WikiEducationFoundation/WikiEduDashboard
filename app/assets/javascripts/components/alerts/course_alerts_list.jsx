import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchCourseAlerts } from '../../actions/alert_actions';

const CourseAlertsList = (props) => {
  const dispatch = useDispatch();

  useEffect(() => {
    // sets the title of this tab
    document.title = `${props.course.title} - ${I18n.t('courses.alerts')}`;
    // This adds the specific course alerts to the state, to be used in AlertsHandler
    dispatch(fetchCourseAlerts(props.course_id));
  }, []);

  return (
    <AlertsHandler
      alertLabel={I18n.t('alerts.alert_label')}
      noAlertsLabel={I18n.t('alerts.no_alerts')}
    />
  );
};

export default (CourseAlertsList);
