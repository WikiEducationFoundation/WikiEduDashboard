import React from 'react';
import ReactDOM from 'react-dom';
import Modal from '../common/modal.jsx';
import CourseStore from '../../stores/course_store.js';
import ValidationStore from '../../stores/validation_store.js';
import ValidationActions from '../../actions/validation_actions.js';
import CourseActions from '../../actions/course_actions.js';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import Calendar from '../common/calendar.jsx';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';

const CourseClonedModal = React.createClass({
  displayName: 'CourseClonedModal',

  propTypes: {
    course: React.PropTypes.object
  },

  mixins: [ValidationStore.mixin, CourseStore.mixin],

  getInitialState() {
    return {
      error_message: ValidationStore.firstMessage(),
      course: this.props.course
    };
  },

  setAnyDatesSelected(bool) {
    return this.setState({ anyDatesSelected: bool });
  },

  setBlackoutDatesSelected(bool) {
    return this.setState({ blackoutDatesSelected: bool });
  },

  setNoBlackoutDatesChecked() {
    const { checked } = ReactDOM.findDOMNode(this.refs.noDates);
    return this.updateCourse('no_day_exceptions', checked);
  },

  storeDidChange() {
    this.handleCourse();
    return this.setState({
      error_message: ValidationStore.firstMessage(),
      tempCourseId: CourseUtils.generateTempId(this.state.course)
    });
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
      ValidationActions.setValid('exists');
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
    if (ValidationStore.isValid()) {
      ValidationActions.setInvalid('exists', I18n.t('courses.creator.checking_for_uniqueness'), true);
      return setTimeout(() => {
        const updatedCourse = $.extend(true, {}, { course: this.state.course });
        updatedCourse.course.cloned_status = this.cloneCompletedStatus;
        const { slug } = this.state.course;
        const id = CourseUtils.generateTempId(this.state.course);
        CourseActions.updateClonedCourse(updatedCourse, slug, id);
        return this.setState({ isPersisting: true });
      }
      , 0);
    }
  },

  isNewCourse(course) {
    // it's "new" if the cloned_course status comes back from the server as updated.
    return course.cloned_status === 2;
  },

  handleCourse() {
    if (!this.state.isPersisting) { return; }
    if (this.isNewCourse(this.props.course)) {
      return window.location = `/courses/${this.props.course.slug}`;
    } else if (!ValidationStore.getValidation('exists').valid) {
      $('html, body').animate({ scrollTop: 0 });
      return this.setState({ isPersisting: false });
    }
  },

  saveEnabled() {
    if (!this.state.valuesUpdated || !this.state.dateValuesUpdated) { return false; }
    if (__guard__(this.state.course.weekdays, x => x.indexOf(1)) >= 0 && (__guard__(this.state.course.day_exceptions, x1 => x1.length) > 0 || this.state.course.no_day_exceptions)) {
      return true;
    }
    return false;
  },

  render() {
    let buttonClass = 'button dark';
    buttonClass += this.state.isPersisting ? ' working' : '';

    let errorMessage;
    if (this.state.error_message) {
      errorMessage = <div className="warning">{this.state.error_message}</div>;
    }

    const dateProps = CourseDateUtils.dateProps(this.state.course);
    const saveDisabled = this.saveEnabled() ? '' : 'disabled';

    const slugPartValidationRegex = /^[\w\-\s,']+$/;

    return (
      <Modal>
        <div className="wizard__panel active cloned-course">
          <h3>{I18n.t('courses.creator.clone_successful')}</h3>
          <p>{I18n.t('courses.creator.clone_successful_details')}</p>
          {errorMessage}
          <div className="wizard__form">
            <div className="column" id="details_column">
              <TextInput
                id="course_title"
                onChange={this.updateCourse}
                value={this.state.course.title}
                value_key="title"
                required={true}
                validation={slugPartValidationRegex}
                editable={true}
                label={I18n.t('courses.creator.course_title')}
                placeholder={I18n.t('courses.title')}
              />

              <TextInput
                id="course_school"
                onChange={this.updateCourse}
                value={this.state.course.school}
                value_key="school"
                required={true}
                validation={slugPartValidationRegex}
                editable={true}
                label={I18n.t('courses.creator.course_school')}
                placeholder={I18n.t('courses.school')}
              />

              <TextInput
                id="course_term"
                onChange={this.updateCourse}
                value={this.state.course.term}
                value_key="term"
                required={true}
                validation={slugPartValidationRegex}
                editable={true}
                label={I18n.t('courses.creator.course_term')}
                placeholder={I18n.t('courses.creator.course_term_placeholder')}
              />

              <TextInput
                id="course_subject"
                onChange={this.updateCourse}
                value={this.state.course.subject}
                value_key="subject"
                editable={true}
                label={I18n.t('courses.creator.course_subject')}
                placeholder={I18n.t('courses.creator.subject')}
              />
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
              <TextAreaInput
                id="course_description"
                onChange={this.updateCourse}
                value={this.state.course.description}
                value_key="description"
                editable={true}
                placeholder={I18n.t('courses.creator.course_description')}
              />
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
                required={true}
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
                required={true}
                editable={true}
                label={I18n.t('courses.creator.assignment_end')}
                placeholder={I18n.t('courses.creator.assignment_end_placeholder')}
                date_props={dateProps.timeline_end}
                validation={CourseDateUtils.isDateValid}
                enabled={Boolean(this.state.course.start)}
                isClearable={false}
              />
            </div>

            <div className="column">
              <Calendar
                course={this.state.course}
                editable={true}
                setAnyDatesSelected={this.setAnyDatesSelected}
                setBlackoutDatesSelected={this.setBlackoutDatesSelected}
                shouldShowSteps={false}
                calendarInstructions={I18n.t('courses.creator.cloned_course_calendar_instructions')}
              />
              <label> {I18n.t('courses.creator.no_class_holidays')}
                <input type="checkbox" onChange={this.setNoBlackoutDatesChecked} ref="noDates" />
              </label>

            </div>
            <button onClick={this.saveCourse} disabled={saveDisabled} className={buttonClass}>{I18n.t('courses.creator.save_cloned_course')}</button>
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
