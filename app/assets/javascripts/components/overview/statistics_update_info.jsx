import React from 'react';
import createReactClass from 'create-react-class';
import moment from 'moment';
import PropTypes from 'prop-types';
import StatisticsUpdateModal from './statistics_update_modal';
import { withRouter } from 'react-router';
import { connect } from 'react-redux';
import getQueuesLatency from '../../actions/queues_latency_actions';


const StatisticsUpdateInfo = createReactClass({
  displayName: 'StatisticsUpdateInfo',

  propTypes: {
    course: PropTypes.object.isRequired,
    queuesLatency: PropTypes.object.isRequired,
  },

  getInitialState() {
    return {
      showModal: false
    };
  },

  componentWillMount() {
    this.props.getQueuesLatency();
  },

  getLatencyFromState(end, start, queuesLatency) {
    const days = moment(end).diff(moment(start), 'days');
    if (days < 3) {
      return queuesLatency.short;
    }
    return queuesLatency.medium;
  },


  getUpdateTimesInformation(course, queuesLatency) {
    let lastSuccessfulUpdateMessage = '';
            let nextUpdateMessage = '';
    let isNextUpdateAfter = false;
    if (course.updates.last_update === null) {
      const latency = this.getLatencyFromState(course.end, course.start, queuesLatency);
      const nextUpdateExpectedTime = moment().add(latency, 'seconds');
      isNextUpdateAfter = nextUpdateExpectedTime.isAfter();
      // nextUpdateMessage = `${I18n.t('metrics.first_update')}: ${nextUpdateExpectedTime.fromNow()}`;
      nextUpdateMessage = `next upd: ${nextUpdateExpectedTime.fromNow()}`;
    } else {
      const updateTimesLogs = Object.values(course.flags.update_logs).filter(log => log.end_time !== undefined);

      if (updateTimesLogs.length === 0) return null;

      const lastSuccessfulUpdate = updateTimesLogs[updateTimesLogs.length - 1].end_time;
      const lastSuccessfulUpdateMoment = moment.utc(lastSuccessfulUpdate);
      const averageDelay = course.updates.average_delay;
      if (lastSuccessfulUpdate) {
        lastSuccessfulUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastSuccessfulUpdateMoment.fromNow()}`;
        const nextUpdateExpectedTime = lastSuccessfulUpdateMoment.add(averageDelay, 'seconds');
        isNextUpdateAfter = nextUpdateExpectedTime.isAfter();
        nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${nextUpdateExpectedTime.fromNow()}`;
      }
    }
  return [lastSuccessfulUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
  },

  toggleModal() {
    this.setState({
      showModal: !this.state.showModal
    });
  },

  render() {
    const course = this.props.course;
    const queuesLatency = this.props.queuesLatency;
    if (Features.wikiEd && !course.ended) {
      return <div />;
    }

    const updateTimesInformation = this.getUpdateTimesInformation(course, queuesLatency);
    // Render Modal
    if (this.state.showModal) {
      return (
        <StatisticsUpdateModal
          course={course}
          getUpdateTimesInformation={updateTimesInformation}
          toggleModal={this.toggleModal}
        />
      );
    }


    let updateTimesMessage = '';
    if (updateTimesInformation !== null) {
      const [lastSuccessfulUpdateMessage, nextUpdateMessage, isNextUpdateAfter] = updateTimesInformation;
      updateTimesMessage = isNextUpdateAfter ? `${lastSuccessfulUpdateMessage}. ${nextUpdateMessage}. ` : `${lastSuccessfulUpdateMessage}. `;
    }

    // Render update time information along with 'See More' link to open modal
    return (
      <div className="statistics-update-info pull-right mb2">
        <small>
          { updateTimesMessage }<a onClick={this.toggleModal} href="#">{I18n.t('metrics.update_statistics_link')}</a>
        </small>
      </div>
    );
  }
});

const mapStateToProps = state => ({
  queuesLatency: state.queuesLatency,
});

const mapDispatchToProps = {
  getQueuesLatency,
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(StatisticsUpdateInfo));
