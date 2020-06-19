import React from 'react';
import createReactClass from 'create-react-class';
import moment from 'moment';
import Modal from '../common/modal';
import PropTypes from 'prop-types';

const StatisticsUpdateInfo = createReactClass({
  displayName: 'StatisticsUpdateInfo',

  propTypes: {
    course: PropTypes.object.isRequired,
  },

  getInitialState() {
    return {
      renderModal: false
    };
  },

  getUpdateMessage() {
    const course = this.props.course;

    const lastUpdate = course.updates.last_update.end_time;
    const lastUpdateMoment = moment.utc(lastUpdate);
    const averageDelay = course.updates.average_delay;
    let lastUpdateMessage = '';
    if (lastUpdate) {
      lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastUpdateMoment.fromNow()}`;
    }

    const nextUpdateExpectedTime = lastUpdateMoment.add(averageDelay, 'seconds');
    let nextUpdateMessage = '';
    if (nextUpdateExpectedTime.isAfter()) {
      nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${nextUpdateExpectedTime.fromNow()}`;
    }

    let courseUpdateErrorMessage = '';
    const errorCount = course.updates.last_update.error_count;
    if (errorCount > 0) {
      courseUpdateErrorMessage = `${I18n.t('metrics.error_count_message', { error_count: errorCount })} `;
    }

    return (
      <p>{lastUpdateMessage}<br/>{nextUpdateMessage}<br/>{courseUpdateErrorMessage}</p>
    );
  },

  toggleModal() {
    this.setState({
      renderModal: !this.state.renderModal
    });
  },

  render() {
    const course = this.props.course;

    if ((Features.wikiEd && !course.ended) || !course.updates.last_update) {
      return <div />;
    }

    if (this.state.renderModal) {
      return (
        <Modal className="course-update-stats">
          <div>{ this.getUpdateMessage() }</div>
          <br/>
          <button className="button dark" onClick={this.toggleModal}>{I18n.t('metrics.close_modal')}</button>
        </Modal>
      );
    }

    return (
      <button className="button small dark" onClick={this.toggleModal}>{I18n.t('metrics.update_statistics_button')}</button>
    );
  }
});

export default StatisticsUpdateInfo;
