import React, { useState } from 'react';
import DatePicker from '../common/date_picker.jsx';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';

const CourseDates = (props) => {
  const [day, setDay] = useState('none');

  const updateDay = (e) => {
    setDay(e.target.value);
    const day_value = e.target.value;
    props.updateCourseProps({ calender_view_day: day_value });
    props.updateCourseAction('calender_view_day', day_value);
  };

  const updateCourseDates = (key, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(props.course, key, value);
    props.updateCourseProps(updatedCourse);
  };
  const dateProps = CourseDateUtils.dateProps(props.course);
  const timeZoneMessage = (
    <p className="form-help-text">
      {I18n.t('courses.time_zone_message')}
    </p>
  );

  const calendarDropdown = (
    <div>
      <label>
        <div>Select Day for Calender:</div>
        <select value={day} onChange={updateDay}>
          <option value="none" disabled>-- Select Option --</option>
          <option value="0">Sunday</option>
          <option value="1">Monday</option>
        </select>
      </label>
    </div>
  );

  let timelineStart;
  let timelineEnd;
  let timelineText;
  if (props.enableTimeline) {
    timelineText = (
      <div>
        <hr />
        <p><strong>{CourseUtils.i18n('creator.separate_event_dates')}</strong></p>
        <p>{CourseUtils.i18n('creator.separate_event_dates_info')}</p>
      </div>
    );
    timelineStart = (
      <DatePicker
        course = {props.course}
        id="course_timeline_start"
        onChange={updateCourseDates}
        value={props.course.timeline_start}
        value_key="timeline_start"
        editable
        label={CourseUtils.i18n('creator.assignment_start', props.stringPrefix)}
        placeholder={I18n.t('courses.creator.assignment_start_placeholder')}
        blank
        isClearable={true}
        showTime={props.showTimeValues}
      />
    );
    timelineEnd = (
      <DatePicker
        course = {props.course}
        id="course_timeline_end"
        onChange={updateCourseDates}
        value={props.course.timeline_end}
        value_key="timeline_end"
        editable
        label={CourseUtils.i18n('creator.assignment_end', props.stringPrefix)}
        placeholder={I18n.t('courses.creator.assignment_end_placeholder')}
        blank
        date_props={dateProps.timeline_end}
        enabled={!!props.course.timeline_start}
        isClearable={true}
        showTime={props.showTimeValues}
      />
    );
  }
  return (
    <div className={props.courseDateClass}>
      <div>{calendarDropdown}</div>
      <p>{CourseUtils.i18n('creator.course_dates_info', props.stringPrefix)}</p>
      <DatePicker
        course = {props.course}
        id="course_start"
        onChange={updateCourseDates}
        value={props.course.start}
        value_key="start"
        required
        editable
        label={CourseUtils.i18n('creator.start_date', props.stringPrefix)}
        placeholder={I18n.t('courses.creator.start_date_placeholder')}
        blank
        isClearable={false}
        showTime={props.showTimeValues}
      />
      <DatePicker
        course = {props.course}
        id="course_end"
        onChange={updateCourseDates}
        value={props.course.end}
        value_key="end"
        required
        editable
        label={CourseUtils.i18n('creator.end_date', props.stringPrefix)}
        placeholder={I18n.t('courses.creator.end_date_placeholder')}
        blank
        date_props={dateProps.end}
        enabled={!!props.course.start}
        isClearable={false}
        showTime={props.showTimeValues}
      />
      {timelineText}
      {timelineStart}
      {timelineEnd}
      {props.showTimeValues ? timeZoneMessage : null}
      {/* these are only shown when the user has chosen program type as article scoped */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: '1em',
        }}
      >
        {props.back && (
          <button
            onClick={props.back}
            id="back"
            className="dark button button__submit next"
          >
            Back
          </button>
        )}
        {props.firstErrorMessage && (
          <span
            className="red"
            style={{
              marginLeft: 'auto',
            }}
          >
            {props.firstErrorMessage}
          </span>
        )}
        {props.next && (
          <button
            onClick={props.next}
            id="next"
            className="dark button button__submit next"
          >
            Next
          </button>
        )}
      </div>
    </div>
  );
};

export default CourseDates;
