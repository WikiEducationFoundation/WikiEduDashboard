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

  getUpdateTimesMessage() {
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

    return `${lastUpdateMessage}. ${nextUpdateMessage} `;
  },

  getCourseUpdateErrorMessage() {
    let courseUpdateErrorMessage = '';
    const errorCount = this.props.course.updates.last_update.error_count;
    if (errorCount > 0) {
      courseUpdateErrorMessage = `${I18n.t('metrics.error_count_message', { error_count: errorCount })} `;
    }
    return courseUpdateErrorMessage;
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

    // If no errors, display only update time information
    if (course.updates.last_update.error_count === 0) {
      return (
        <div className="pull-right mb2">
          <small>{this.getUpdateTimesMessage()}</small>
        </div>
      );
    }

    // If there are errors

    // Render Modal
    if (this.state.showModal) {
      const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');

      return (
        <Modal modalClass="course-error-stats">
            <h3>{I18n.t('metrics.course_update_error_heading')}</h3>
            { this.getCourseUpdateErrorMessage() }
            <br/>
            {I18n.t('metrics.replag_info')}
            <br/>
            <a href="https://replag.toolforge.org/" className="button small mt2" target="_blank">{I18n.t('metrics.replag_link')}</a>
            <br/>
            <button className="button dark mt2" onClick={this.toggleModal}>{I18n.t('metrics.close_modal')}</button>
            <br/>
            <small className="mt1">{helpMessage}</small>
        </Modal>
      );
    }

    // Render update time information along with 'See More' button to open modal
    return (
      <div className="pull-right mb2">
        <small>
          {this.getUpdateTimesMessage()}<a onClick={this.toggleModal} href='#'>{I18n.t('metrics.update_statistics_button')}</a>
        </small>
      </div>
    );
  }
});

export default StatisticsUpdateInfo;
