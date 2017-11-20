import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Panel from './panel.jsx';
import DatePicker from '../common/date_picker.jsx';
import Calendar from '../common/calendar.jsx';
import CourseActions from '../../actions/course_actions.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import ValidationStore from '../../stores/validation_store.js';

const FormPanel = createReactClass({
  displayName: 'FormPanel',

  propTypes: {
    course: PropTypes.object.isRequired,
    shouldShowSteps: PropTypes.bool
  },

  setAnyDatesSelected(bool) {
    return this.setState({ anyDatesSelected: bool });
  },

  setBlackoutDatesSelected(bool) {
    return this.setState({ blackoutDatesSelected: bool });
  },
  setNoBlackoutDatesChecked() {
    const { checked } = this.noDates;
    const toPass = this.props.course;
    toPass.no_day_exceptions = checked;
    return CourseActions.updateCourse(toPass);
  },

  updateCourseDates(valueKey, value) {
    const updatedCourse = CourseDateUtils.updateCourseDates(this.props.course, valueKey, value);
    return CourseActions.updateCourse(updatedCourse);
  },

  saveCourse() {
    if (ValidationStore.isValid()) {
      CourseActions.persistCourse(this.props, this.props.course.slug);
      return true;
    }
    alert(I18n.t('error.form_errors'));
    return false;
  },
  nextEnabled() {
    if (__guard__(this.props.course.weekdays, x => x.indexOf(1)) >= 0 && (__guard__(this.props.course.day_exceptions, x1 => x1.length) > 0 || this.props.course.no_day_exceptions)) {
      return true;
    }
    return false;
  },

  render() {
    const dateProps = CourseDateUtils.dateProps(this.props.course);

    const step1 = this.props.shouldShowSteps ?
      <h2><span>1.</span><small> Confirm the course’s start and end dates.</small></h2>
    :
      <p>Confirm the course’s start and end dates.</p>;

    const rawOptions = (
      <div>
        <div className="course-dates__step">
          {step1}
          <div className="vertical-form full-width">
            <DatePicker
              onChange={this.updateCourseDates}
              value={this.props.course.start}
              value_key="start"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label="Course Start"
            />
            <DatePicker
              onChange={this.updateCourseDates}
              value={this.props.course.end}
              value_key="end"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label="Course End"
              date_props={dateProps.end}
              enabled={Boolean(this.props.course.start)}
            />
          </div>
        </div>
        <hr />
        <div className="course-dates__step">
          <p>{I18n.t('wizard.assignment_description')}</p>
          <div className="vertical-form full-width">
            <DatePicker
              onChange={this.updateCourseDates}
              value={this.props.course.timeline_start}
              value_key="timeline_start"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_start')}
              date_props={dateProps.timeline_start}
            />
            <DatePicker
              onChange={this.updateCourseDates}
              value={this.props.course.timeline_end}
              value_key="timeline_end"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_end')}
              date_props={dateProps.timeline_end}
              enabled={Boolean(this.props.course.start)}
            />
          </div>
        </div>
        <hr />
        <div className="wizard__form course-dates course-dates__step">
          <Calendar
            course={this.props.course}
            editable={true}
            save={true}
            setAnyDatesSelected={this.setAnyDatesSelected}
            setBlackoutDatesSelected={this.setBlackoutDatesSelected}
            calendarInstructions= {I18n.t('wizard.calendar_instructions')}
          />
          <label> I have no class holidays
            <input type="checkbox" onChange={this.setNoBlackoutDatesChecked} ref={(checkbox) => {this.noDates = checkbox;}} />
          </label>
        </div>
      </div>
    );

    return (
      <Panel
        {...this.props}
        raw_options={rawOptions}
        nextEnabled={this.nextEnabled}
        saveCourse={this.saveCourse}
        helperText = "Select meeting days and holiday dates, then continue."
      />
    );
  }
});

export default FormPanel;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
