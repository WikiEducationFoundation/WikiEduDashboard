import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { withRouter } from 'react-router';
import AlertsHandler from './alerts_handler.jsx';
import { fetchTaggedCourseAlerts, filterAlerts } from '../../actions/alert_actions';

class TaggedCourseAlerts extends React.Component {
  constructor(props) {
    super(props);

    this.getTag = this.getTag.bind(this);
  }

  componentDidMount() {
    // This adds the specific campaign alerts to the state, to be used in AlertsHandler
    this.props.fetchTaggedCourseAlerts(this.getTag());
  }

  getTag() {
    return `${this.props.match.params.tag}`;
  }

  render() {
    return (
      <AlertsHandler
        alertLabel={I18n.t('campaign.alert_label')}
        noAlertsLabel={I18n.t('campaign.no_alerts')}
      />
    );
  }
}

TaggedCourseAlerts.propTypes = {
  fetchTaggedCourseAlerts: PropTypes.func
};

const mapDispatchToProps = { fetchTaggedCourseAlerts, filterAlerts };

export default withRouter(connect(null, mapDispatchToProps)(TaggedCourseAlerts));
