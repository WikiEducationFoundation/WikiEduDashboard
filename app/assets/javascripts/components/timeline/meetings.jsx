import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import CourseLink from '../common/course_link.jsx';
import Calendar from '../common/calendar.jsx';
import Modal from '../common/modal.jsx';
import DatePicker from '../common/date_picker.jsx';
import CourseActions from '../../actions/course_actions.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { isValid } from '../../utils/validation_utils.js';
import { setInvalid } from '../../actions/validation_actions.js';

const Meetings = createReactClass({
  displayName: 'Meetings',

  propTypes: {
    weeks: PropTypes.array, // Comes indirectly from TimelineHandler
    course: PropTypes.object
  },

  disableSave(bool) {
    return this.setState({ saveDisabled: bool });
  },

  updateCourse(valueKey, value) {
    const toPass = this.props.course;
    toPass[valueKey] = value;
    return CourseActions.updateCourse(toPass);
  },

  updateCourseDates(valueKey, value) {
    const updatedCourse = CourseDateUtils.updateCourseDates(this.props.course, valueKey, value);
    return CourseActions.updateCourse(updatedCourse);
  },

  saveCourse(e) {
    if (isValid(this.props.validations, this.props.setInvalid)) {
      return CourseActions.persistCourse({ course: this.props.course }, this.props.course.slug);
    }
    e.preventDefault();
    return alert(I18n.t('error.form_errors'));
  },

  updateCheckbox(e) {
    this.updateCourse('no_day_exceptions', e.target.checked);
    return this.updateCourse('day_exceptions', '');
  },

  saveDisabledClass(course) {
    const blackoutDatesSelected = course.day_exceptions && course.day_exceptions.length > 0;
    const anyDatesSelected = course.weekdays && course.weekdays.indexOf(1) >= 0;
    const enable = blackoutDatesSelected || (anyDatesSelected && this.props.course.no_day_exceptions);
    if (enable) { return ''; }
    return 'disabled';
  },

  render() {
    const course = this.props.course;
    if (!course) { return <div />; }
    const dateProps = CourseDateUtils.dateProps(course);
    let courseLinkClass = 'dark button ';
    courseLinkClass += this.saveDisabledClass(course);
    const courseLinkTarget = `/courses/${course.slug}/timeline`;

    return (
      <Modal >
        <div className="wizard__panel active">
          <h3>{I18n.t('timeline.course_dates')}</h3>
          <div className="course-dates__step">
            <p>{I18n.t('timeline.course_dates_instructions')}</p>
            <div className="vertical-form full-width">
              <DatePicker
                onChange={this.updateCourseDates}
                value={course.start}
                value_key="start"
                validation={CourseDateUtils.isDateValid}
                editable={true}
                label={I18n.t('timeline.course_start')}
              />
              <DatePicker
                onChange={this.updateCourseDates}
                value={course.end}
                value_key="end"
                validation={CourseDateUtils.isDateValid}
                editable={true}
                label={I18n.t('timeline.course_end')}
                date_props={dateProps.end}
                enabled={Boolean(course.start)}
              />
            </div>
          </div>
          <hr />
          <div className="course-dates__step">
            <p>{I18n.t('timeline.assignment_dates_instructions')}</p>
            <div className="vertical-form full-width">
              <DatePicker
                onChange={this.updateCourseDates}
                value={course.timeline_start}
                value_key="timeline_start"
                editable={true}
                validation={CourseDateUtils.isDateValid}
                label={I18n.t('courses.assignment_start')}
                date_props={dateProps.timeline_start}
              />
              <DatePicker
                onChange={this.updateCourseDates}
                value={course.timeline_end}
                value_key="timeline_end"
                editable={true}
                validation={CourseDateUtils.isDateValid}
                label={I18n.t('courses.assignment_end')}
                date_props={dateProps.timeline_end}
                enabled={Boolean(course.start)}
              />
            </div>
          </div>
          <hr />
          <div className="wizard__form course-dates course-dates__step">
            <Calendar
              course={course}
              save={true}
              editable={true}
              calendarInstructions={I18n.t('courses.course_dates_calendar_instructions')}
              weeks={this.props.weeks}
            />
            <label> {I18n.t('timeline.no_class_holidays')}
              <input
                type="checkbox"
                onChange={this.updateCheckbox}
                ref="noDates"
                checked={this.props.course.day_exceptions === '' && this.props.course.no_day_exceptions}
              />
            </label>
          </div>
          <div className="wizard__panel__controls">
            <div className="left" />
            <div className="right">
              <CourseLink
                onClick={this.saveCourse}
                className={courseLinkClass}
                to={courseLinkTarget}
                id="course_cancel"
              >
                Done
              </CourseLink>
            </div>
          </div>
        </div>
      </Modal>
    );
  }
}
);

const mapStateToProps = state => ({
  validations: state.validation.validations,
});

const mapDispatchToProps = ({
  setInvalid,
});

export default connect(mapStateToProps, mapDispatchToProps)(Meetings);
