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
      const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');
      let missingDataMessage;
      
      if (course.type === 'ArticleScopedProgram') {
          missingDataMessage = `${I18n.t('metrics.article_scoped_program_info')} ${I18n.t('metrics.replag_info')}`;
      } else {
        missingDataMessage = `${I18n.t('metrics.replag_info')}`;
      }

      return (
        <Modal modalClass="course-data-update-modal">
          <b>{I18n.t('metrics.update_status_heading')}</b>
          <br/>
          { this.getCourseUpdateErrorMessage() }
          <ul>
            <li>{I18n.t('metrics.total_updates')}: { this.getTotalNumberOfUpdates() }</li>
            <li>{ nextUpdateMessage }</li>
          </ul>
          <b>{I18n.t('metrics.missing_data_heading')}</b>
          <br/>
          { missingDataMessage }
          <br/>
          <a href="https://replag.toolforge.org/" target="_blank">{I18n.t('metrics.replag_link')}</a>
          <br/>
          <small className="mt1">{ helpMessage }</small>
          <br/>
          <button className="button dark" onClick={this.toggleModal}>{I18n.t('metrics.close_modal')}</button>
        </Modal>
      );
    }

    // Render update time information along with 'See More' button to open modal
    return (
      <div className="course-data-update pull-right mb2">
        <small>
          { updateTimesMessage }<a onClick={this.toggleModal} href="#">{I18n.t('metrics.update_statistics_link')}</a>
        </small>
      </div>
    );
  }
});

export default StatisticsUpdateInfo;
