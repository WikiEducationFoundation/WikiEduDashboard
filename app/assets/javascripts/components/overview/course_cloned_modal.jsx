import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Modal from '../common/modal.jsx';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import Calendar from '../common/calendar.jsx';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';

const CourseClonedModal = createReactClass({
  displayName: 'CourseClonedModal',

  propTypes: {
    course: PropTypes.object.isRequired,
    updateCourse: PropTypes.func.isRequired,
    updateClonedCourse: PropTypes.func.isRequired,
    currentUser: PropTypes.object.isRequired,
    setValid: PropTypes.func.isRequired,
    setInvalid: PropTypes.func.isRequired,
    isValid: PropTypes.bool.isRequired,
    activateValidations: PropTypes.func.isRequired,
    firstErrorMessage: PropTypes.string
  },

  getInitialState() {
    return {
      course: this.props.course
    };
  },

  componentWillReceiveProps(newProps) {
    let isPersisting = this.state.isPersisting;
    if (newProps.firstErrorMessage && !this.props.firstErrorMessage) {
      document.querySelector('.wizard').scrollTo({ top: 0, behavior: 'smooth' });
      isPersisting = false;
    }
    return this.setState({
      isPersisting,
      tempCourseId: CourseUtils.generateTempId(this.state.course)
    });
  },

  setAnyDatesSelected(bool) {
    return this.setState({ anyDatesSelected: bool });
  },

  setBlackoutDatesSelected(bool) {
    return this.setState({ blackoutDatesSelected: bool });
  },

  setNoBlackoutDatesChecked() {
    const { checked } = this.noDates;
    return this.updateCourse('no_day_exceptions', checked);
  },

  cloneCompletedStatus: 2,

  updateCourse(valueKey, value) {
    const updatedCourse = $.extend(true, {}, this.state.course);
    updatedCourse[valueKey] = value;
    this.setState({
      valuesUpdated: true,
      course: updatedCourse
    });

    // Term starts out blank and must be added.
    if (valueKey === 'term') {
      return this.props.setValid('exists');
    }
    // If term is already set and any slug components are changed, reset 'exists' to valid.
    if (updatedCourse.term && ['title', 'school', 'term'].includes(valueKey)) {
      this.props.setValid('exists');
    }
  },

  updateCourseDates(valueKey, value) {
    const updatedCourse = CourseDateUtils.updateCourseDates(this.state.course, valueKey, value);
    return this.setState({
      dateValuesUpdated: true,
      course: updatedCourse
    });
  },

  saveCourse() {
    this.props.activateValidations();
    if (this.props.isValid) {
      this.props.setInvalid('exists', I18n.t('courses.creator.checking_for_uniqueness'), true);
      const { slug } = this.state.course;
      const updatedCourse = CourseUtils.cleanupCourseSlugComponents(this.state.course);
      updatedCourse.cloned_status = this.cloneCompletedStatus;

      const newSlug = CourseUtils.generateTempId(updatedCourse);
      updatedCourse.slug = newSlug;
      this.props.updateClonedCourse(updatedCourse, slug, newSlug);
      return this.setState({ isPersisting: true });
    }
  },

  isNewCourse(course) {
    // it's "new" if the cloned_course status comes back from the server as updated.
    return course.cloned_status === 2;
  },

  saveEnabled() {
    // You must be logged in and have permission to edit the course.
    // This will be the case if you created it (and are therefore the instructor) or if you are an admin.
    if (!this.props.currentUser.isNonstudent) { return false; }
    // ClassroomProgramCourse conditions
    if (this.props.course.type === 'ClassroomProgramCourse') {
      if (!this.state.valuesUpdated || !this.state.dateValuesUpdated) { return false; }
      if (__guard__(this.state.course.weekdays, x => x.indexOf(1)) >= 0 && (__guard__(this.state.course.day_exceptions, x1 => x1.length) > 0 || this.state.course.no_day_exceptions)) {
        return true;
      }
      return false;
    }
    // non-ClassroomProgramCourse conditions
    if (this.state.valuesUpdated && this.state.dateValuesUpdated) { return true; }
    return false;
  },

  render() {
    const i18nPrefix = this.props.course.string_prefix;
    let buttonClass = 'button dark';
    buttonClass += this.state.isPersisting ? ' working' : '';

    let errorMessage;
    if (this.props.firstErrorMessage) {
      errorMessage = <div className="warning">{this.props.firstErrorMessage}</div>;
    } else if (!this.props.currentUser.id) {
      errorMessage = <div className="warning">{I18n.t('courses.please_log_in')}</div>;
    } else if (!this.props.currentUser.isNonstudent) {
      errorMessage = <div className="warning">{CourseUtils.i18n('not_permitted', i18nPrefix)}</div>;
    }

    const dateProps = CourseDateUtils.dateProps(this.state.course);
    const saveDisabled = this.saveEnabled() ? '' : 'disabled';

    // Form components that are conditional on course type
    let expectedStudents;
    let courseSubject;
    let fullDates;
    let rightColumn;
    let infoIcon;
    // Specific to ClassroomProgramCourse
    if (this.props.course.type === 'ClassroomProgramCourse') {
      expectedStudents = (
        <TextInput
          id="course_expected_students"
          onChange={this.updateCourse}
          value={this.state.course.expected_students.toString()}
          value_key="expected_students"
          editable={true}
          type="number"
          label={I18n.t('courses.creator.expected_number')}
          placeholder={I18n.t('courses.creator.expected_number')}
        />
      );
      courseSubject = (
        <TextInput
          id="course_subject"
          onChange={this.updateCourse}
          value={this.state.course.subject}
          value_key="subject"
          editable={true}
          label={I18n.t('courses.creator.course_subject')}
          placeholder={I18n.t('courses.creator.subject')}
        />
      );
      fullDates = (
        <div>
          <DatePicker
            id="course_start"
            onChange={this.updateCourseDates}
            value={this.state.dateValuesUpdated ? this.state.course.start : null}
            value_key="start"
            required={true}
            editable={true}
            label={I18n.t('courses.creator.start_date')}
            placeholder={I18n.t('courses.creator.start_date_placeholder')}
            validation={CourseDateUtils.isDateValid}
            isClearable={false}
          />
          <DatePicker
            id="course_end"
            onChange={this.updateCourseDates}
            value={this.state.dateValuesUpdated ? this.state.course.end : null}
            value_key="end"
            required={true}
            editable={true}
            label={I18n.t('courses.creator.end_date')}
            placeholder={I18n.t('courses.creator.end_date_placeholder')}
            date_props={dateProps.end}
            validation={CourseDateUtils.isDateValid}
            enabled={Boolean(this.state.course.start)}
            isClearable={false}
          />
          <DatePicker
            id="timeline_start"
            onChange={this.updateCourseDates}
            value={this.state.dateValuesUpdated ? this.state.course.timeline_start : null}
            value_key="timeline_start"
            editable={true}
            label={I18n.t('courses.creator.assignment_start')}
            placeholder={I18n.t('courses.creator.assignment_start_placeholder')}
            date_props={dateProps.timeline_start}
            validation={CourseDateUtils.isDateValid}
            enabled={Boolean(this.state.course.start)}
            isClearable={false}
          />
          <DatePicker
            id="timeline_end"
            onChange={this.updateCourseDates}
            value={this.state.dateValuesUpdated ? this.state.course.timeline_end : null}
            value_key="timeline_end"
            editable={true}
            label={I18n.t('courses.creator.assignment_end')}
            placeholder={I18n.t('courses.creator.assignment_end_placeholder')}
            date_props={dateProps.timeline_end}
            validation={CourseDateUtils.isDateValid}
            enabled={Boolean(this.state.course.start)}
            isClearable={false}
          />
        </div>
      );
      rightColumn = (
        <div className="column">
          <Calendar
            course={this.state.course}
            editable={true}
            setAnyDatesSelected={this.setAnyDatesSelected}
            setBlackoutDatesSelected={this.setBlackoutDatesSelected}
            shouldShowSteps={false}
            calendarInstructions={I18n.t('courses.creator.cloned_course_calendar_instructions')}
            updateCourse={this.props.updateCourse}
          />
          <label> {I18n.t('courses.creator.no_class_holidays')}
            <input id="no_holidays" type="checkbox" onChange={this.setNoBlackoutDatesChecked} ref={(checkbox) => { this.noDates = checkbox; }} />
          </label>
        </div>
      );
    // Specific to non-ClassroomProgramCourse
    } else {
      infoIcon = (
        <div className="tooltip-trigger">
          <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
          <div className="tooltip large dark">
            <p>
              {CourseUtils.i18n('creator.course_when', i18nPrefix)}
            </p>
          </div>
        </div>
      );
      rightColumn = (
        <div className="column">
          <DatePicker
            id="course_start"
            onChange={this.updateCourseDates}
            value={this.state.dateValuesUpdated ? this.state.course.start : null}
            value_key="start"
            required={true}
            editable={true}
            label={CourseUtils.i18n('creator.start_date', i18nPrefix)}
            placeholder={I18n.t('courses.creator.start_date_placeholder')}
            validation={CourseDateUtils.isDateValid}
            isClearable={false}
            showTime={true}
          />
          <DatePicker
            id="course_end"
            onChange={this.updateCourseDates}
            value={this.state.dateValuesUpdated ? this.state.course.end : null}
            value_key="end"
            required={true}
            editable={true}
            label={CourseUtils.i18n('creator.end_date', i18nPrefix)}
            placeholder={I18n.t('courses.creator.end_date_placeholder')}
            date_props={dateProps.end}
            validation={CourseDateUtils.isDateValid}
            enabled={Boolean(this.state.course.start)}
            isClearable={false}
            showTime={true}
          />
          <p className="form-help-text">
            {I18n.t('courses.time_zone_message')}
          </p>
        </div>
      );
    }
    const termInput = (
      <div className="terminput">
        <TextInput
          id="course_term"
          onChange={this.updateCourse}
          value={this.state.course.term}
          value_key="term"
          required={true}
          validation={CourseUtils.courseSlugRegex()}
          editable={true}
          label={CourseUtils.i18n('creator.course_term', i18nPrefix)}
          placeholder={CourseUtils.i18n('creator.course_term_placeholder', i18nPrefix)}
        />
        {infoIcon}
      </div>
    );

    return (
      <Modal>
        <div className="container">
          <div className="wizard__panel active cloned-course">
            <h3 id="clone_modal_header">{CourseUtils.i18n('creator.clone_successful', i18nPrefix)}</h3>
            <p>{CourseUtils.i18n('creator.clone_successful_details', i18nPrefix)}</p>
            {errorMessage}
            <div className="wizard__form">
              <div className="column" id="details_column">
                <TextInput
                  id="course_title"
                  onChange={this.updateCourse}
                  value={this.state.course.title}
                  value_key="title"
                  required={true}
                  validation={CourseUtils.courseSlugRegex()}
                  editable={true}
                  label={CourseUtils.i18n('creator.course_title', i18nPrefix)}
                  placeholder={CourseUtils.i18n('title', i18nPrefix)}
                />
                <TextInput
                  id="course_school"
                  onChange={this.updateCourse}
                  value={this.state.course.school}
                  value_key="school"
                  required={true}
                  validation={CourseUtils.courseSlugRegex()}
                  editable={true}
                  label={CourseUtils.i18n('creator.course_school', i18nPrefix)}
                  placeholder={CourseUtils.i18n('school', i18nPrefix)}
                />
                {termInput}
                {courseSubject}
                {expectedStudents}
                {fullDates}
                <TextAreaInput
                  id="course_description"
                  onChange={this.updateCourse}
                  value={this.state.course.description}
                  value_key="description"
                  editable={true}
                  placeholder={CourseUtils.i18n('creator.course_description', i18nPrefix)}
                />
              </div>
              {rightColumn}
              <button onClick={this.saveCourse} disabled={saveDisabled} className={buttonClass}>{CourseUtils.i18n('creator.save_cloned_course', i18nPrefix)}</button>
            </div>
          </div>
        </div>
      </Modal>
    );
  }
});

export default CourseClonedModal;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
