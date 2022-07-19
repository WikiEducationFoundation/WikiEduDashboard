import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import moment from 'moment';
import Week from '../timeline/week.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

const emptyWeeksAtBeginning = function (weekMeetings) {
  let count = 0;
  for (let i = 0; i < weekMeetings.length; i += 1) {
    const week = weekMeetings[i];
    if (week.length > 0) { return count; }
    count += 1;
  }
};

const emptyWeeksUntil = function (weekMeetings, weekIndex) {
  let count = 0;
  const iterable = weekMeetings.slice(0, weekIndex);
  for (let i = 0; i < iterable.length; i += 1) {
    const week = iterable[i];
    if (week.length === 0) { count += 1; }
  }
  return count;
};

const ThisWeek = ({ course, weeks, current_user }) => {
  let weekIndex;
  let thisWeekMeetings;
  let weekMeetings;
  let week;
  let title;
  let weekComponent;
  let noWeeks;

  const currentWeek = CourseDateUtils.currentWeekIndex(course.timeline_start);
  const weeksBeforeTimeline = CourseDateUtils.weeksBeforeTimeline(course);

  if (weeks) {
    weekIndex = currentWeek + 1;

    weekMeetings = CourseDateUtils.weekMeetings(course, course.day_exceptions);
    const emptyWeeksAtStart = emptyWeeksAtBeginning(weekMeetings);
    const daysUntilBeginning = emptyWeeksAtStart * 7;
    const isFirstWeek = moment().diff(course.timeline_start, 'days') <= daysUntilBeginning;
    if (isFirstWeek) {
      const weekMeetingsIndex = emptyWeeksAtBeginning(weekMeetings);
      thisWeekMeetings = weekMeetings[weekMeetingsIndex];
      weekIndex = weekMeetingsIndex + 1;
      week = weeks[0];
      title = I18n.t('timeline.first_week_title');
    } else {
      thisWeekMeetings = weekMeetings[currentWeek];
      const emptyWeeksSoFar = emptyWeeksUntil(weekMeetings, currentWeek);
      week = weeks[currentWeek - emptyWeeksSoFar];
    }
  }

  if (week) {
    const meetingsProp = weekMeetings ? thisWeekMeetings : [];
    weekComponent = (
      <Week
        week={week}
        timeline_start={course.timeline_start}
        timeline_end={course.timeline_end}
        index={weekIndex}
        key={week.id}
        editable={false}
        blocks= {week.blocks}
        moveBlock={null}
        deleteWeek={null}
        showTitle={false}
        meetings={meetingsProp}
        weeksBeforeTimeline={weeksBeforeTimeline}
        trainingLibrarySlug={course.training_library_slug}
        current_user={current_user}
      />
    );
  } else {
    noWeeks = (
      <li className="row view-all">
        <div><p>{I18n.t('timeline.nothing_this_week')}</p></div>
      </li>
    );
  }

  const timelineUrl = `/courses/${course.slug}/timeline`;

  return (
    <div className="module course__this-week">
      <div className="section-header">
        <h3>{title || I18n.t('timeline.this_week_title_default')}</h3>
        <Link to={timelineUrl} className="pull-right button ghost-button block__this-week-button" >{I18n.t('timeline.view_full_timeline')}</Link>
      </div>
      <ul className="list-unstyled">
        {weekComponent}
        {noWeeks}
      </ul>
    </div>
  );
};

ThisWeek.propTypes = {
  course: PropTypes.object.isRequired,
  weeks: PropTypes.array.isRequired,
  current_user: PropTypes.object
};

export default ThisWeek;
