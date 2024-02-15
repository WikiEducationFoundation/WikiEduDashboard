import React, { useState } from 'react';
import PropTypes from 'prop-types';
import StatisticsUpdateModal from './statistics_update_modal';
import { getUpdateMessage } from '../../utils/statistic_update_info_utils';

const StatisticsUpdateInfo = ({ course }) => {
  const [showModal, setShowModal] = useState(false);

  const toggleModal = () => {
    setShowModal(!showModal);
  };

  if (Features.wikiEd && !course.ended) {
    return <div />;
  }

  const [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter] = getUpdateMessage(course);

  if (showModal) {
    return (
      <StatisticsUpdateModal
        course={course}
        isNextUpdateAfter={isNextUpdateAfter}
        nextUpdateMessage={nextUpdateMessage}
        toggleModal={toggleModal}
      />
    );
  }
  const updateTimesMessage = isNextUpdateAfter ? `${lastUpdateMessage} ${nextUpdateMessage} ` : `${lastUpdateMessage} `;

  // Render update time information and if some updates were made a 'See More' link to open modal
  return (
    <div className="statistics-update-info pull-right mb2">
      <small>
        {updateTimesMessage} {(course.flags.first_update || course.flags.update_logs) && <a onClick={toggleModal} href="#">{I18n.t('metrics.update_statistics_link')}</a>}
      </small>
    </div>
  );
};

StatisticsUpdateInfo.propTypes = {
  course: PropTypes.object.isRequired,
};

export default StatisticsUpdateInfo;
