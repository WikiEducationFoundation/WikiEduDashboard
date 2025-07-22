import React from 'react';
import PropTypes from 'prop-types';
import CourseLink from '../common/course_link.jsx';
import DateCalculator from '../../utils/date_calculator.js';

const EmptyWeek = ({
  emptyTimeline,
  edit_permissions,
  usingCustomTitles,
  course,
  timeline_start,
  timeline_end,
  index,
  weeksBeforeTimeline,
  addWeek
}) => {
  let week;
  // Three types of empty weeks:

  // 1. If timeline is empty and user can edit it, show info and links to get started.
  if (emptyTimeline && edit_permissions) {
    let wizardLink;
    let wizardLinkTransition;
    if (course.type === 'ClassroomProgramCourse') {
      const wizardUrl = `/courses/${course.slug}/timeline/wizard`;
      wizardLinkTransition = I18n.t('timeline.empty_week_3');
      wizardLink = <CourseLink to={wizardUrl} className="empty-week-clickable">{I18n.t('timeline.empty_week_4')}</CourseLink>;
    }

    week = (
      <p className="week__no-activity__get-started">
        {I18n.t('timeline.empty_week_1')}&nbsp;
        <span className="empty-week-clickable" onClick={addWeek}>{I18n.t('timeline.empty_week_2')}</span>&nbsp;
        {wizardLinkTransition}&nbsp;
        {wizardLink}
      </p>);

  // 2. If timeline is empty but user cannot edit, just note that timeline is empty.
  } else if (emptyTimeline) {
    week = (
      <p className="week__no-activity__get-started">
        {I18n.t('timeline.no_timeline')}
      </p>);

  // 3. If timeline is not empty, show the blackout week message.
  } else {
    week = (<h1 className="h3">{I18n.t('timeline.no_activity_this_week')}</h1>);
  }

  const dateCalc = new DateCalculator(timeline_start, timeline_end, index, { zeroIndexed: false });

  const weekNumber = index + weeksBeforeTimeline;

  let header;
  const datesStr = `${dateCalc.start()} - ${dateCalc.end()}`;
  if (usingCustomTitles) {
    header = (
      <div className="week__week-header">
        <p>
          {I18n.t('timeline.week_number', { number: datesStr })}
        </p>
      </div>
    );
  } else {
    header = (
      <div className="week__week-header">
        <p>
          {I18n.t('timeline.week_number', { number: weekNumber || 1 })} <span className="week-range"> ({datesStr})</span>
        </p>
      </div>
    );
  }

  return (
    <li className={`week week-${index}`}>
      {header}
      <div className="week__no-activity">
        {week}
      </div>
    </li>
  );
};

EmptyWeek.propTypes = {
  emptyTimeline: PropTypes.bool,
  edit_permissions: PropTypes.bool,
  usingCustomTitles: PropTypes.bool,
  course: PropTypes.object,
  timeline_start: PropTypes.string,
  timeline_end: PropTypes.string,
  index: PropTypes.number,
  weeksBeforeTimeline: PropTypes.number,
  addWeek: PropTypes.func.isRequired
};

export default EmptyWeek;
