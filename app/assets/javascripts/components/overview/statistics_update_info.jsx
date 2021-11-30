import React from 'react';
import createReactClass from 'create-react-class';
import moment from 'moment';
import PropTypes from 'prop-types';
import StatisticsUpdateModal from './statistics_update_modal';

const StatisticsUpdateInfo = createReactClass({
  displayName: 'StatisticsUpdateInfo',

  propTypes: {
    course: PropTypes.object.isRequired,
  },

  getInitialState() {
    return {
      showModal: false
    };
  },

  getUpdateTimesInformation() {
    const course = this.props.course;
    let lastSuccessfulUpdateMessage = '';
    let nextUpdateMessage = '';
    let isNextUpdateAfter = false;
    if (course.updates.last_update === null) {
     lastSuccessfulUpdateMessage = `${I18n.t('metrics.no_update')}`;
     if (course.flags.first_update) {
      const nextUpdateExpectedTime = this.firstUpdateTime();
      isNextUpdateAfter = nextUpdateExpectedTime.isAfter();
      nextUpdateMessage = `${I18n.t('metrics.first_update')}: ${nextUpdateExpectedTime.fromNow()}`;
      lastSuccessfulUpdateMessage = `${I18n.t('metrics.enqueued_update')}`;
     }
     } else {
      const lastSuccessfulUpdate = this.lastSuccessfulUpdateTime();
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

  firstUpdateTime() {
  const first_update = this.props.course.flags.first_update;
  const latency = Math.round(first_update.queue_latency);
    const enqueuedAt = moment(first_update.enqueued_at);
    return moment(enqueuedAt).add(latency, 'seconds');
  },

  lastSuccessfulUpdateTime() {
    const updateTimesLogs = Object.values(this.props.course.flags.update_logs).filter(log => log.end_time !== undefined);

    if (updateTimesLogs.length === 0) return null;

    return updateTimesLogs[updateTimesLogs.length - 1].end_time;
  },

  toggleModal() {
    this.setState({
      showModal: !this.state.showModal
    });
  },

  render() {
    const course = this.props.course;

    if (Features.wikiEd && !course.ended) {
      return <div />;
    }

    const updateTimesInformation = this.getUpdateTimesInformation();
    // Render Modal
    if (this.state.showModal) {
      return (
        <StatisticsUpdateModal
          course={course}
          updateTimesInformation={updateTimesInformation}
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
          {updateTimesMessage} {course.updates.last_update !== null && <a onClick={this.toggleModal} href="#">{I18n.t('metrics.update_statistics_link')}</a>}
        </small>
      </div>
    );
  }
});


export default StatisticsUpdateInfo;
