import React from 'react';
import TextAreaInput from '../common/text_area_input.jsx';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';

const CourseForm = ({ courseFormClass, campaign, course_utils, string_prefix, updateCourseAction, course, term, courseLevel, subject, expectedStudents, language, project, privacyCheckbox, showTimeValues, updateCourseDateAction, dateProps, eventCheckbox, eventClass, timelineStart, timelineEnd, timeZoneMessage, descriptionRequired, roleDescription }) => {
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
