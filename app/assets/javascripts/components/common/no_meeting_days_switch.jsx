import React from 'react';
import PropTypes from 'prop-types';

const NoMeetingDaysSwitch = ({ noMeetingDates, course, updateCourse }) => {
  const handleNoMeetingDays = () => {
    const { checked } = noMeetingDates.current;
    course.no_meeting_days = !checked;
    if (!checked) {
      course.weekdays = '1111111';
    } else {
      course.weekdays = '0000000';
    }
    return updateCourse(course);
  };
  return (
    <>
      <div className="switch-container">
        <span>{I18n.t('wizard.no_meetings')}</span>
        <label
          htmlFor="no_meeting_days"
          className="switch"
          aria-label={I18n.t('wizard.no_meetings')}
        >
          <input
            id="no_meeting_days"
            type="checkbox"
            onChange={handleNoMeetingDays}
            checked={!course.no_meeting_days}
            ref={noMeetingDates}
            className="no-meeting-day-checkbox"
          />
          <span className="slider round"/>
        </label>
      </div>
      <span className="no-meeting-notes">{I18n.t('wizard.no_meetings_notes')}</span>
    </>
  );
};

NoMeetingDaysSwitch.propTypes = {
  noMeetingDates: PropTypes.shape({ current: PropTypes.any }),
  course: PropTypes.object,
  updateCourse: PropTypes.func,
};

export default NoMeetingDaysSwitch;
