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

  // Update numbers (ids) are stored incrementally as counts in update_logs, so the
  // last update number is the total number of updates till now
  getTotalNumberOfUpdates() {
    const updateNumbers = Object.keys(this.props.course.flags.update_logs);

    return updateNumbers[updateNumbers.length - 1];
  },

  getCourseUpdateErrorMessage() {
    const errorCount = this.props.course.updates.last_update.error_count;

    return `${I18n.t('metrics.error_count_message', { error_count: errorCount })} `;
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
      const totalUpdatesMessage = `${I18n.t('metrics.total_updates')}: ${this.getTotalNumberOfUpdates()}`;

      let missingDataMessage;
      if (course.type === 'ArticleScopedProgram') {
          missingDataMessage = `${I18n.t('metrics.article_scoped_program_info')} ${I18n.t('metrics.replag_info')}`;
      } else {
        missingDataMessage = `${I18n.t('metrics.replag_info')}`;
      }

      return (
        <StatisticsUpdateModal
          errorMessage={this.getCourseUpdateErrorMessage()}
          totalUpdatesMessage={totalUpdatesMessage}
          nextUpdateMessage={nextUpdateMessage}
          missingDataMessage={missingDataMessage}
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
