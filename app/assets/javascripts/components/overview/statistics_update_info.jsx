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
    const lastUpdate = course.updates.last_update.end_time;
    const lastUpdateMoment = moment.utc(lastUpdate);
    const averageDelay = course.updates.average_delay;
    let lastUpdateMessage = '';
    let nextUpdateMessage = '';
    let isNextUpdateAfter = null;

    if (lastUpdate) {
      lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastUpdateMoment.fromNow()}`;
      const nextUpdateExpectedTime = lastUpdateMoment.add(averageDelay, 'seconds');
      isNextUpdateAfter = nextUpdateExpectedTime.isAfter();
      nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${nextUpdateExpectedTime.fromNow()}`;
    }

    return [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
  },

  toggleModal() {
    this.setState({
      showModal: !this.state.showModal
    });
  },

  render() {
    const course = this.props.course;

    if ((Features.wikiEd && !course.ended) || !course.updates.last_update) {
      return <div />;
    }

    const [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter] = this.getUpdateTimesInformation();
    const updateTimesMessage = isNextUpdateAfter ? `${lastUpdateMessage}. ${nextUpdateMessage}. ` : `${lastUpdateMessage}. `;

    // If no errors, display only update time information
    if (course.updates.last_update.error_count === 0) {
      return (
        <div className="pull-right mb2">
          <small>{ updateTimesMessage }</small>
        </div>
      );
    }

    // If there are errors

    // Render Modal
    if (this.state.showModal) {
      return (
        <StatisticsUpdateModal
          course={course}
          nextUpdateMessage={nextUpdateMessage}
          toggleModal={this.toggleModal}
        />
      );
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

export default StatisticsUpdateInfo;
