import React from 'react';
import ReactDOM from 'react-dom';
import { Link } from 'react-router';

import CourseStore from '../../stores/course_store.js';
import UserCoursesStore from '../../stores/user_courses_store.js';
import CourseActions from '../../actions/course_actions.js';
import ValidationStore from '../../stores/validation_store.js';
import ValidationActions from '../../actions/validation_actions.js';
import CourseCreationActions from '../../actions/course_creation_actions.js';
import ServerActions from '../../actions/server_actions.js';

import Modal from '../common/modal.jsx';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import TransitionGroup from 'react-addons-css-transition-group';

import _ from 'lodash';

import { getUserId } from '../../stores/user_id_store.js';
import { getDefaultCourseType, getCourseStringPrefix, getUseStartAndEndTimes } from '../../stores/course_attributes_store';

const getState = () => {
  return {
    course: CourseStore.getCourse(),
    error_message: ValidationStore.firstMessage(),
    user_courses: _.reject(UserCoursesStore.getUserCourses(), { type: 'LegacyCourse' })
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
      showCourseDropdown: false,
      default_course_type: getDefaultCourseType(),
      course_string_prefix: getCourseStringPrefix(),
      use_start_and_end_times: getUseStartAndEndTimes()
    };

    return $.extend({}, inits, getState());
  },

  componentWillMount() {
    CourseActions.addCourse();

    // If a campaign slug is provided, fetch the campaign.
    // The regex allows for any number of URL parameters, while only capturing the campaign_slug parameter
    const campaignParam = window.location.search.match(/\?.*?campaign_slug=(.*?)(?:$|&)/);
    if (campaignParam && campaignParam[1]) {
      CourseCreationActions.fetchCampaign(campaignParam[1]);
    }

    return ServerActions.fetchCoursesForUser(getUserId());
  },

  storeDidChange() {
    this.setState(getState());
    if (this.state.course.school !== '' && this.state.title !== '') {
      this.state.tempCourseId = CourseUtils.generateTempId(this.state.course);
    }
    else {
      this.state.tempCourseId = '';
    }
    return this.handleCourse();
  },

  saveCourse() {
    if (ValidationStore.isValid() && this.expectedStudentsIsValid() && this.dateTimesAreValid()) {
      this.setState({ isSubmitting: true });
      ValidationActions.setInvalid(
        'exists',
        CourseUtils.i18n('creator.checking_for_uniqueness', this.state.course_string_prefix),
        true
      );
      return ServerActions.checkCourse('exists', CourseUtils.generateTempId(this.state.course));
    }
  },

  handleCourse() {
    if (this.state.shouldRedirect === true) {
      window.location = `/courses/${this.state.course.slug}?modal=true`;
    }
    if (!this.state.isSubmitting && !this.state.justSubmitted) { return; }

    if (ValidationStore.isValid()) {
      if (this.state.course.slug && this.state.justSubmitted) {
        // This has to be a window.location set due to our limited ReactJS scope
        if (this.state.default_course_type === 'ClassroomProgramCourse') {
          window.location = `/courses/${this.state.course.slug}/timeline/wizard`;
        } else {
          window.location = `/courses/${this.state.course.slug}`;
        }
      } else if (!this.state.justSubmitted) {
        this.setState({ course: CourseUtils.cleanupCourseSlugComponents(this.state.course) });
        ServerActions.saveCourse($.extend(true, {}, { course: this.state.course }));
        this.setState({ isSubmitting: false });
        this.setState({ justSubmitted: true });
      }
    } else if (!ValidationStore.getValidation('exists').valid) {
      this.setState({ isSubmitting: false });
    }
  },

  updateCourse(key, value) {
    const courseAttrs = $.extend(true, {}, this.state.course);
    courseAttrs[key] = value;
    CourseActions.updateCourse(courseAttrs);
    if (_.includes(['title', 'school', 'term'], key)) {
      return ValidationActions.setValid('exists');
    }
  },

  updateCourseDates(key, value) {
    const updatedCourse = CourseDateUtils.updateCourseDates(this.state.course, key, value);
    CourseActions.updateCourse(updatedCourse);
  },

  expectedStudentsIsValid() {
    if (this.state.course.expected_students === '0' && this.state.default_course_type === 'ClassroomProgramCourse') {
      ValidationActions.setInvalid('expected_students', I18n.t('application.field_required'));
      return false;
    }
    return true;
  },

  dateTimesAreValid() {
    const startDateTime = new Date(this.state.course.start);
    const endDateTime = new Date(this.state.course.end);

    if (startDateTime >= endDateTime) {
      ValidationActions.setInvalid('end', I18n.t('application.field_invalid_date_time'));
      return false;
    }
    return true;
  },

  showForm() {
    return this.setState({ shouldShowForm: true });
  },

  showCourseDropdown() {
    return this.setState({ showCourseDropdown: true });
  },

  cancelClone() {
    return this.setState({ showCourseDropdown: false });
  },

  useThisClass() {
    const select = ReactDOM.findDOMNode(this.refs.courseSelect);
    const courseId = select.options[select.selectedIndex].getAttribute('data-id-key');
    ServerActions.cloneCourse(courseId);
    return this.setState({ isSubmitting: true, shouldRedirect: true });
  },

  render() {
    let formStyle;
    if (this.state.isSubmitting === true) {
      formStyle = { pointerEvents: 'none', opacity: 0.5 };
    }

    let formClass = 'wizard__form';

    formClass += ((this.state.shouldShowForm === true || this.state.user_courses.length === 0) ? '' : ' hidden');

    const cloneOptions = formClass.match(/hidden/) && !this.state.showCourseDropdown ? '' : ' hidden';
    const controlClass = `wizard__panel__controls ${formClass}`;
    const selectClass = this.state.showCourseDropdown === true ? '' : ' hidden';
    const options = this.state.user_courses.map((course, i) => <option key={i} data-id-key={course.id}>{course.title}</option>);
    const selectClassName = `select-container ${selectClass}`;

    let term;
    let subject;
    let expectedStudents;

    let descriptionRequired = false;
    if (this.state.default_course_type === 'ClassroomProgramCourse') {
      descriptionRequired = true;
      term = (
        <TextInput
          id="course_term"
          onChange={this.updateCourse}
          value={this.state.course.term}
          value_key="term"
          required
          validation={CourseUtils.courseSlugRegex()}
          editable
          label={CourseUtils.i18n('creator.course_term', this.state.course_string_prefix)}
          placeholder={CourseUtils.i18n('creator.course_term_placeholder', this.state.course_string_prefix)}
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
          placeholder={I18n.t('courses.creator.subject')}
        />
      );
      expectedStudents = (
        <TextInput
          id="course_expected_students"
          onChange={this.updateCourse}
          value={String(this.state.course.expected_students)}
          value_key="expected_students"
          editable
          required
          type="number"
          max="999"
          label={CourseUtils.i18n('creator.expected_number', this.state.course_string_prefix)}
          placeholder={CourseUtils.i18n('creator.expected_number', this.state.course_string_prefix)}
        />
      );
    }

    let language;
    let project;
    let campaign;
    if (this.state.default_course_type !== 'ClassroomProgramCourse') {
      language = (
        <TextInput
          id="course_language"
          onChange={this.updateCourse}
          value={this.state.course.language}
          value_key="language"
          editable
          label={I18n.t('courses.creator.course_language')}
          placeholder="en"
        />
      );
      project = (
        <TextInput
          id="course_project"
          onChange={this.updateCourse}
          value={this.state.course.project}
          value_key="project"
          editable
          label={I18n.t('courses.creator.course_project')}
          placeholder="wikipedia"
        />
      );
    }
    if (this.state.course.initial_campaign_title) {
      campaign = (
        <TextInput
          value={this.state.course.initial_campaign_title}
          label={I18n.t('campaign.campaign')}
        />
      );
    }

    const dateProps = CourseDateUtils.dateProps(this.state.course);

    const timeZoneMessage = (
      <p className="form-help-text">
        {I18n.t('courses.time_zone_message')}
      </p>
    );
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
              <button className="button dark" onClick={this.showCourseDropdown}>{CourseUtils.i18n('creator.clone_previous', this.state.course_string_prefix)}</button>
            </div>
            <div className={selectClassName}>
              <select id="reuse-existing-course-select" ref="courseSelect">{options}</select>
              <button className="button dark" onClick={this.useThisClass}>{CourseUtils.i18n('creator.clone_this', this.state.course_string_prefix)}</button>
              <button className="button dark right" onClick={this.cancelClone}>{CourseUtils.i18n('cancel', this.state.course_string_prefix)}</button>
            </div>
            <div className={formClass}>
              <div className="column">

                {campaign}
                <TextInput
                  id="course_title"
                  onChange={this.updateCourse}
                  value={this.state.course.title}
                  value_key="title"
                  required
                  validation={CourseUtils.courseSlugRegex()}
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
                  validation={CourseUtils.courseSlugRegex()}
                  editable
                  label={CourseUtils.i18n('creator.course_school', this.state.course_string_prefix)}
                  placeholder={CourseUtils.i18n('creator.course_school', this.state.course_string_prefix)}
                />
                {term}
                {subject}
                {expectedStudents}
                {language}
                {project}
              </div>
              <div className="column">
                <TextAreaInput
                  id="course_description"
                  onChange={this.updateCourse}
                  value={this.state.course.description}
                  value_key="description"
                  required={descriptionRequired}
                  editable
                  placeholder={CourseUtils.i18n('creator.course_description', this.state.course_string_prefix)}
                />
                <DatePicker
                  id="course_start"
                  onChange={this.updateCourseDates}
                  value={this.state.course.start}
                  value_key="start"
                  required
                  editable
                  label={CourseUtils.i18n('creator.start_date', this.state.course_string_prefix)}
                  placeholder={I18n.t('courses.creator.start_date_placeholder')}
                  blank
                  isClearable={false}
                  showTime={this.state.use_start_and_end_times}
                />
                <DatePicker
                  id="course_end"
                  onChange={this.updateCourseDates}
                  value={this.state.course.end}
                  value_key="end"
                  required
                  editable
                  label={CourseUtils.i18n('creator.end_date', this.state.course_string_prefix)}
                  placeholder={I18n.t('courses.creator.end_date_placeholder')}
                  blank
                  date_props={dateProps.end}
                  enabled={!!this.state.course.start}
                  isClearable={false}
                  showTime={this.state.use_start_and_end_times}
                />
                {this.state.use_start_and_end_times ? timeZoneMessage : null}
              </div>
            </div>
            <div className={controlClass}>
              <div className="left"><p>{this.state.tempCourseId}</p></div>
              <div className="right">
                <div><p className="red">{this.state.error_message}</p></div>
                <Link className="button" to="/" id="course_cancel">{I18n.t('application.cancel')}</Link>
                <button onClick={this.saveCourse} className="dark button button__submit">{CourseUtils.i18n('creator.create_button', this.state.course_string_prefix)}</button>
              </div>
            </div>
          </div>
        </Modal>
      </TransitionGroup>
    );
  }
});

export default CourseCreator;
