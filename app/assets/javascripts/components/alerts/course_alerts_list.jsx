import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchCourseAlerts } from '../../actions/alert_actions';

class CourseAlertsList extends React.Component {
  componentDidMount() {
    // sets the title of this tab
    document.title = `${this.props.course.title} - ${I18n.t('courses.alerts')}`;
    // This adds the specific course alerts to the state, to be used in AlertsHandler
    this.props.fetchCourseAlerts(this.props.course_id);
  }

  render() {
    return (
      <AlertsHandler
        alertLabel={I18n.t('alerts.alert_label')}
        noAlertsLabel={I18n.t('alerts.no_alerts')}
      />
    );
  }
}

CourseAlertsList.propTypes = {
  fetchCourseAlerts: PropTypes.func,
};

const mapDispatchToProps = { fetchCourseAlerts };

export default connect(null, mapDispatchToProps)(CourseAlertsList);
