import React from 'react';
import ReactDOM from 'react-dom';
import { Link } from 'react-router';

import CourseStore from '../../stores/course_store.coffee';
import UserCoursesStore from '../../stores/user_courses_store.coffee';
import CourseActions from '../../actions/course_actions.js';
import ValidationStore from '../../stores/validation_store.coffee';
import ValidationActions from '../../actions/validation_actions.js';
import ServerActions from '../../actions/server_actions.js';

import Modal from '../common/modal.cjsx';
import TextInput from '../common/text_input.cjsx';
import TextAreaInput from '../common/text_area_input.cjsx';
import CourseUtils from '../../utils/course_utils.js';
import TransitionGroup from 'react-addons-css-transition-group';

import moment from 'moment';
import _ from 'lodash';

import { getUserId } from '../../stores/user_id_store.js';
import { getDefaultCourseType, getCourseStringPrefix } from '../../stores/course_attributes_store';

const getState = () => {
  return {
    course: CourseStore.getCourse(),
    error_message: ValidationStore.firstMessage(),
    user_courses: UserCoursesStore.getUserCourses()
  };
};

const CourseCreator = React.createClass({
  displayName: 'CourseCreator',

  mixins: [CourseStore.mixin, ValidationStore.mixin, UserCoursesStore.mixin],

  getInitialState() {
    const inits = {
      tempCourseId: '',
      isSubmitting: false,
      shouldShowForm: false,
      shouldShowCourseDropdown: false,
      default_course_type: getDefaultCourseType(),
      course_string_prefix: getCourseStringPrefix()
    };
    return $.extend({}, inits, getState());
  },

  componentWillMount() {
    CourseActions.addCourse();
    return ServerActions.fetchCoursesForUser(getUserId());
  },

  storeDidChange() {
    this.setState(getState());
    this.state.tempCourseId = CourseUtils.generateTempId(this.state.course);
    return this.handleCourse();
  },

  saveCourse() {
    if (ValidationStore.isValid()) {
      this.setState({ isSubmitting: true });
      ValidationActions.setInvalid('exists', 'This course is being checked for uniqueness', true);
      return ServerActions.checkCourse('exists', CourseUtils.generateTempId(this.state.course));
    }
  },

  handleCourse() {
    if (this.state.shouldRedirect === true) {
      window.location = `/courses/${this.state.course.slug}?modal=true`;
    }
    if (!this.state.isSubmitting) { return; }

    if (ValidationStore.isValid()) {
      if (this.state.course.slug !== null) {
        // This has to be a window.location set due to our limited ReactJS scope
        if (this.state.default_course_type === 'ClassroomProgramCourse') {
          window.location = `/courses/${this.state.course.slug}/timeline/wizard`;
        } else {
          window.location = `/courses/${this.state.course.slug}`;
        }
      } else {
        this.setState({ course: CourseUtils.cleanupCourseSlugComponents(this.state.course) });
        ServerActions.saveCourse($.extend(true, {}, { course: this.state.course }));
      }
    } else if (!ValidationStore.getValidation('exists').valid) {
      this.setState({ isSubmitting: false });
    }
  },

  updateCourse(valueKey, value) {
    const toPass = $.extend(true, {}, this.state.course);
    toPass[valueKey] = value;
    CourseActions.updateCourse(toPass);
    if (_.includes(['title', 'school', 'term'], valueKey)) {
      return ValidationActions.setValid('exists');
    }
  },

  showForm() {
    return this.setState({ shouldShowForm: true });
  },

  showCourseDropdown() {
    return this.setState({ showCourseDropdown: true });
  },

  useThisClass() {
    const select = ReactDOM.findDOMNode(this.refs.courseSelect);
    const courseId = select.options[select.selectedIndex].getAttribute('data-id-key');
    ServerActions.cloneCourse(courseId);
    return this.setState({ isSubmitting: true, shouldRedirect: true });
  },

  render() {
    const formStyle = {};
    if (this.state.isSubmitting === true) { formStyle.opacity = 0.5; }
    if (this.state.isSubmitting === true) { formStyle.pointerEvents = 'none'; }

    let formClass = 'wizard__form';

    formClass += ((this.state.shouldShowForm === true || this.state.user_courses.length === 0) ? '' : ' hidden');

    let cloneOptions = formClass.match(/hidden/) && !this.state.showCourseDropdown ? '' : ' hidden';

    let controlClass = 'wizard__panel__controls';
    controlClass += ` ${formClass}`;

    let selectClass = this.state.showCourseDropdown === true ? '' : ' hidden';

    let options = this.state.user_courses.map((course, i) => <option key={i} data-id-key={course.id}>{course.title}</option>);

    let term;
    let subject;
    let expectedStudents;
    if (this.state.default_course_type === 'ClassroomProgramCourse') {
      term = (
        <TextInput
          id="course_term"
          onChange={this.updateCourse}
          value={this.state.course.term}
          value_key="term"
          required
          validation={/^[\w\-\s\,\']+$/}
          editable
          label={CourseUtils.i18n('creator.course_term', this.state.course_string_prefix)}
          placeholder="Term"
        />
      );
      subject = (
        <TextInput
          id="course_subject"
          onChange={this.updateCourse}
          value={this.state.course.subject}
          value_key="subject"
          editable
          label={CourseUtils.i18n('creator.course_subject', this.state.course_string_prefix)}
          placeholder="Subject"
        />
      );
      expectedStudents = (
        <TextInput
          id="course_expected_students"
          onChange={this.updateCourse}
          value={this.state.course.expected_students}
          value_key="expected_students"
          editable
          type="number"
          label={CourseUtils.i18n('creator.expected_number', this.state.course_string_prefix)}
          placeholder="Expected number of students"
        />
      );
    }

    return (
      <TransitionGroup
        transitionName="wizard"
        component="div"
        transitionEnterTimeout={500}
        transitionLeaveTimeout={500}
      >
        <Modal key="modal">
          <div className="wizard__panel active" style={formStyle}>
            <h3>{CourseUtils.i18n('creator.create_new', this.state.course_string_prefix)}</h3>
            <p>{CourseUtils.i18n('creator.intro', this.state.course_string_prefix)}</p>
            <div className={cloneOptions}>
              <button className="button dark" onClick={this.showForm}>{CourseUtils.i18n('creator.create_label', this.state.course_string_prefix)}</button>
              <button className="button dark" onClick={this.showCourseDropdown}>Clone Previous Course</button>
            </div>
            <div className={selectClass}>
              <select id="reuse-existing-course-select" ref="courseSelect">{options}</select>
              <button className="button dark" onClick={this.useThisClass}>Clone This Course</button>
            </div>
            <div className={formClass}>
              <div className="column">

                <TextInput
                  id="course_title"
                  onChange={this.updateCourse}
                  value={this.state.course.title}
                  value_key="title"
                  required
                  validation={/^[\w\-\s\,\']+$/}
                  editable
                  label={CourseUtils.i18n('creator.course_title', this.state.course_string_prefix)}
                  placeholder={CourseUtils.i18n('creator.course_title', this.state.course_string_prefix)}
                />
                <TextInput
                  id="course_school"
                  onChange={this.updateCourse}
                  value={this.state.course.school}
                  value_key="school"
                  required
                  validation={/^[\w\-\s\,\']+$/}
                  editable
                  label={CourseUtils.i18n('creator.course_school', this.state.course_string_prefix)}
                  placeholder={CourseUtils.i18n('creator.course_school', this.state.course_string_prefix)}
                />
                {term}
                {subject}
                {expectedStudents}
              </div>
              <div className="column">
                <TextAreaInput
                  id="course_description"
                  onChange={this.updateCourse}
                  value={this.state.course.description}
                  value_key="description"
                  editable
                  label={CourseUtils.i18n('creator.course_description', this.state.course_string_prefix)}
                />
                <TextInput
                  id="course_start"
                  onChange={this.updateCourse}
                  value={this.state.course.start}
                  value_key="start"
                  required
                  editable
                  type="date"
                  label={CourseUtils.i18n('creator.start_date', this.state.course_string_prefix)}
                  placeholder="Start date (YYYY-MM-DD)"
                  blank
                  isClearable={false}
                />
                <TextInput
                  id="course_end"
                  onChange={this.updateCourse}
                  value={this.state.course.end}
                  value_key="end"
                  required
                  editable
                  type="date"
                  label={CourseUtils.i18n('creator.end_date', this.state.course_string_prefix)}
                  placeholder="End date (YYYY-MM-DD)"
                  blank
                  date_props={{ minDate: moment(this.state.course.start).add(1, 'week') }}
                  enabled={!!this.state.course.start}
                  isClearable={false}
                />
              </div>
            </div>
            <div className={controlClass}>
              <div className="left"><p>{this.state.tempCourseId}</p></div>
              <div className="right">
                <div><p className="red">{this.state.error_message}</p></div>
                <Link className="button" to="/" id="course_cancel">{I18n.t('application.cancel')}</Link>
                <button onClick={this.saveCourse} className="dark button">{CourseUtils.i18n('creator.create_button', this.state.course_string_prefix)}</button>
              </div>
            </div>
          </div>
        </Modal>
      </TransitionGroup>
    );
  }
});

export default CourseCreator;
