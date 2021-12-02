import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import StatisticsUpdateModal from './statistics_update_modal';
import { getLastUpdateMessage, getFirstUpdateMessage } from '../../utils/statistic_update_info_utils';

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

  getUpdateTimesArray() {
    const course = this.props.course;
    return course.updates.last_update === null ? getFirstUpdateMessage(course) : getLastUpdateMessage(course);
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

    const updateTimesInformation = this.getUpdateTimesArray();
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

    const [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter] = updateTimesInformation;
    const updateTimesMessage = isNextUpdateAfter ? `${lastUpdateMessage} ${nextUpdateMessage} ` : `${lastUpdateMessage} `;


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
