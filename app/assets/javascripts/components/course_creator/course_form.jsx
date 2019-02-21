import React from 'react';
import TextAreaInput from '../common/text_area_input.jsx';
import CreatableInput from '../common/creatable_input.jsx';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import CourseLevelSelector from './course_level_selector.jsx';

const CourseForm = ({ courseFormClass, course_utils, string_prefix, updateCourseAction, course, showEventDates, showEventDatesState, updateCoursePrivacy, showTimeValues, updateCourseDateAction, courseDateUtils, eventClass, roleDescription, defaultCourse }) => {
  const dateProps = courseDateUtils.dateProps(course);
  let term;
  let subject;
  let expectedStudents;
  let courseLevel;

  let descriptionRequired = false;
  if (defaultCourse === 'ClassroomProgramCourse') {
    descriptionRequired = true;
    term = (
      <TextInput
        id="course_term"
        onChange={updateCourseAction}
        value={course.term}
        value_key="term"
        required
        validation={course_utils.courseSlugRegex()}
        editable
        label={course_utils.i18n('creator.course_term', string_prefix)}
        placeholder={course_utils.i18n('creator.course_term_placeholder', string_prefix)}
      />
    );
    subject = (
      <TextInput
        id="course_subject"
        onChange={updateCourseAction}
        value={course.subject}
        value_key="subject"
        editable
        label={course_utils.i18n('creator.course_subject', string_prefix)}
        placeholder={I18n.t('courses.creator.subject')}
      />
    );
    courseLevel = (
      <CourseLevelSelector
        level={course.level}
        updateCourse={updateCourseAction}
      />
    );
    expectedStudents = (
      <TextInput
        id="course_expected_students"
        onChange={updateCourseAction}
        value={String(course.expected_students)}
        value_key="expected_students"
        editable
        required
        type="number"
        max="999"
        label={course_utils.i18n('creator.expected_number', string_prefix)}
        placeholder={course_utils.i18n('creator.expected_number', string_prefix)}
      />
    );
    const options = I18n.t('courses.creator.role_description_options').map((value) => {
      return { label: value, value };
    });
    roleDescription = (
      <CreatableInput
        id="role_description"
        label={I18n.t('courses.creator.role_description')}
        onChange={({ value }) => updateCourseAction('role_description', value)}
        placeholder={I18n.t('courses.creator.role_description_placeholder')}
        options={options}
      />
    );
  }

  let language;
  let project;
  let privacyCheckbox;
  let campaign;
  if (defaultCourse !== 'ClassroomProgramCourse') {
    language = (
      <TextInput
        id="course_language"
        onChange={updateCourseAction}
        value={course.language}
        value_key="language"
        editable
        label={I18n.t('courses.creator.course_language')}
        placeholder="en"
      />
    );
    project = (
      <TextInput
        id="course_project"
        onChange={updateCourseAction}
        value={course.project}
        value_key="project"
        editable
        label={I18n.t('courses.creator.course_project')}
        placeholder="wikipedia"
      />
    );
    privacyCheckbox = (
      <div className="form-group">
        <label htmlFor="course_private">{I18n.t('courses.creator.course_private')}:</label>
        <input
          id="course_private"
          type="checkbox"
          value={true}
          onChange={updateCoursePrivacy}
          checked={!!course.private}
        />
      </div>
    );
  }
  if (course.initial_campaign_title) {
    campaign = (
      <TextInput
        value={course.initial_campaign_title}
        label={I18n.t('campaign.campaign')}
      />
    );
  }
  const timeZoneMessage = (
    <p className="form-help-text">
      {I18n.t('courses.time_zone_message')}
    </p>
  );

  let eventCheckbox;
  let timelineStart;
  let timelineEnd;
  if (defaultCourse !== 'ClassroomProgramCourse') {
    eventCheckbox = (
      <div className="form-group tooltip-trigger">
        <label htmlFor="course_event">
          {I18n.t('courses.creator.separate_event_dates')}
          <span className="tooltip-indicator" />
        </label>
        <div className="tooltip dark">
          <p>{I18n.t('courses.creator.separate_event_dates_info')}</p>
        </div>
        <input
          id="course_event"
          type="checkbox"
          value={true}
          onChange={showEventDates}
          checked={!!showEventDatesState}
        />
      </div>
    );
    timelineStart = (
      <DatePicker
        id="course_timeline_start"
        onChange={updateCourseDateAction}
        value={course.timeline_start}
        value_key="timeline_start"
        editable
        label={course_utils.i18n('creator.assignment_start', string_prefix)}
        placeholder={I18n.t('courses.creator.assignment_start_placeholder')}
        blank
        isClearable={true}
        showTime={showTimeValues}
      />
    );
    timelineEnd = (
      <DatePicker
        id="course_timeline_end"
        onChange={updateCourseDateAction}
        value={course.timeline_end}
        value_key="timeline_end"
        editable
        label={course_utils.i18n('creator.assignment_end', string_prefix)}
        placeholder={I18n.t('courses.creator.assignment_end_placeholder')}
        blank
        date_props={dateProps.timeline_end}
        enabled={!!course.timeline_start}
        isClearable={true}
        showTime={showTimeValues}
      />
    );
  }
  return (
    <div className={courseFormClass}>
      <div className="column">

        {campaign}
        <TextInput
          id="course_title"
          onChange={updateCourseAction}
          value={course.title}
          value_key="title"
          required
          validation={course_utils.courseSlugRegex()}
          editable
          label={course_utils.i18n('creator.course_title', string_prefix)}
          placeholder={course_utils.i18n('creator.course_title', string_prefix)}
        />
        <TextInput
          id="course_school"
          onChange={updateCourseAction}
          value={course.school}
          value_key="school"
          required
          validation={course_utils.courseSlugRegex()}
          editable
          label={course_utils.i18n('creator.course_school', string_prefix)}
          placeholder={course_utils.i18n('creator.course_school', string_prefix)}
        />
        {term}
        {courseLevel}
        {subject}
        {expectedStudents}
        {language}
        {project}
        {privacyCheckbox}
      </div>
      <div className="column">
        <DatePicker
          id="course_start"
          onChange={updateCourseDateAction}
          value={course.start}
          value_key="start"
          required
          editable
          label={course_utils.i18n('creator.start_date', string_prefix)}
          placeholder={I18n.t('courses.creator.start_date_placeholder')}
          blank
          isClearable={false}
          showTime={showTimeValues}
        />
        <DatePicker
          id="course_end"
          onChange={updateCourseDateAction}
          value={course.end}
          value_key="end"
          required
          editable
          label={course_utils.i18n('creator.end_date', string_prefix)}
          placeholder={I18n.t('courses.creator.end_date_placeholder')}
          blank
          date_props={dateProps.end}
          enabled={!!course.start}
          isClearable={false}
          showTime={showTimeValues}
        />
        {eventCheckbox}
        <span className={eventClass}>
          {timelineStart}
          {timelineEnd}
        </span>
        {showTimeValues ? timeZoneMessage : null}
        <span className="text-input-component__label"><strong>{course_utils.i18n('creator.course_description', string_prefix)}:</strong></span>
        <TextAreaInput
          id="course_description"
          onChange={updateCourseAction}
          value={course.description}
          value_key="description"
          required={descriptionRequired}
          editable
          placeholder={course_utils.i18n('creator.course_description_placeholder', string_prefix)}
        />
        {roleDescription}
      </div>
    </div>
  );
};

export default CourseForm;
