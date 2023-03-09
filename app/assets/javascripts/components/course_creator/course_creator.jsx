import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';
import { includes } from 'lodash-es';

import { updateCourse } from '../../actions/course_actions';
import { fetchCampaign, submitCourse, cloneCourse } from '../../actions/course_creation_actions.js';
import { fetchCoursesForUser } from '../../actions/user_courses_actions.js';
import { setValid, setInvalid, checkCourseSlug, activateValidations, resetValidations } from '../../actions/validation_actions';
import { getCloneableCourses, isValid, firstValidationErrorMessage, getAvailableArticles } from '../../selectors';

import Notifications from '../common/notifications.jsx';
import Modal from '../common/modal.jsx';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import CourseType from './course_type.jsx';
import NewOrClone from './new_or_clone.jsx';
import ReuseExistingCourse from './reuse_existing_course.jsx';
import CourseForm from './course_form.jsx';
import CourseDates from './course_dates.jsx';
import { fetchAssignments } from '../../actions/assignment_actions';

const CourseCreator = createReactClass({
  displayName: 'CourseCreator',

  propTypes: {
    course: PropTypes.object.isRequired,
    cloneableCourses: PropTypes.array.isRequired,
    fetchCoursesForUser: PropTypes.func.isRequired,
    courseCreator: PropTypes.object.isRequired,
    updateCourse: PropTypes.func.isRequired,
    submitCourse: PropTypes.func.isRequired,
    fetchCampaign: PropTypes.func.isRequired,
    cloneCourse: PropTypes.func.isRequired,
    loadingUserCourses: PropTypes.bool.isRequired,
    setValid: PropTypes.func.isRequired,
    setInvalid: PropTypes.func.isRequired,
    checkCourseSlug: PropTypes.func.isRequired,
    isValid: PropTypes.bool.isRequired,
    validations: PropTypes.object.isRequired,
    firstErrorMessage: PropTypes.string,
    activateValidations: PropTypes.func.isRequired
  },

  getInitialState() {
    return {
      tempCourseId: '',
      isSubmitting: false,
      showCourseForm: false,
      showCloneChooser: false,
      showEventDates: false,
      showWizardForm: false,
      showCourseDates: false,
      default_course_type: this.props.courseCreator.defaultCourseType,
      course_string_prefix: this.props.courseCreator.courseStringPrefix,
      use_start_and_end_times: this.props.courseCreator.useStartAndEndTimes,
      courseCreationNotice: this.props.courseCreator.courseCreationNotice,
      copyCourseAssignments: false,
    };
  },

  componentDidMount() {
    // If a campaign slug is provided, fetch the campaign.
    const campaignParam = this.campaignParam();
    if (campaignParam) {
      this.props.fetchCampaign(campaignParam);
    }
    this.props.fetchCoursesForUser(window.currentUser.id);
    },

  onDropdownChange(event) {
    this.props.fetchAssignments(event.target.value);
  },
  setCopyCourseAssignments(e) {
    return this.setState({
      copyCourseAssignments: e.target.checked
    });
  },

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.setState({
      tempCourseId: CourseUtils.generateTempId(nextProps.course)
    });
    return this.handleCourse(nextProps.course, nextProps.isValid);
  },

  campaignParam() {
    // The regex allows for any number of URL parameters, while only capturing the campaign_slug parameter
    const campaignParam = window.location.search.match(/\?.*?campaign_slug=(.*?)(?:$|&)/);
    if (campaignParam) {
      return campaignParam[1];
    }
  },

  saveCourse() {
    this.props.activateValidations();
    if (this.props.isValid && this.dateTimesAreValid()) {
      this.setState({ isSubmitting: true });
      this.props.setInvalid(
        'exists',
        CourseUtils.i18n('creator.checking_for_uniqueness', this.state.course_string_prefix),
        true
      );
      return this.props.checkCourseSlug(CourseUtils.generateTempId(this.props.course));
    }
  },

  handleCourse(course, isValidProp) {
    if (this.state.shouldRedirect === true) {
      window.location = `/courses/${course.slug}`;
      return this.setState({ shouldRedirect: false });
    }

    if (!this.state.isSubmitting && !this.state.justSubmitted) {
      return;
    }
    if (isValidProp) {
      if (course.slug && this.state.justSubmitted) {
        // This has to be a window.location set due to our limited ReactJS scope
        if (this.state.default_course_type === 'ClassroomProgramCourse') {
          window.location = `/courses/${course.slug}/timeline/wizard`;
        } else {
          window.location = `/courses/${course.slug}`;
        }
      } else if (!this.state.justSubmitted) {
        const cleanedCourse = CourseUtils.cleanupCourseSlugComponents(course);
        this.setState({ course: cleanedCourse });
        this.setState({ isSubmitting: false });
        this.setState({ justSubmitted: true });
        // If the save callback fails, which will happen if an invalid wiki is submitted,
        // then we must reset justSubmitted so that the user can fix the problem
        // and submit again.
        const onSaveFailure = () => this.setState({ justSubmitted: false });
        this.props.submitCourse({ course: cleanedCourse }, onSaveFailure);
      }
    } else if (!this.props.validations.exists.valid) {
      this.setState({ isSubmitting: false });
    }
  },

  showEventDates() {
    return this.setState({ showEventDates: !this.state.showEventDates });
  },

  updateCourse(key, value) {
    this.props.updateCourse({ [key]: value });
    if (includes(['title', 'school', 'term'], key)) {
      return this.props.setValid('exists');
    }
  },

  updateCourseType(key, value) {
    this.props.updateCourse({ [key]: value });
  },

  expectedStudentsIsValid() {
    if (this.props.course.expected_students === '0' && this.state.default_course_type === 'ClassroomProgramCourse') {
      this.props.setInvalid('expected_students', I18n.t('application.field_required'));
      return false;
    }
    return true;
  },

  titleSubjectAndDescriptionAreValid() {
    if (this.props.course.title === '' || this.props.course.school === '' || this.props.course.description === '') {
      this.props.setInvalid('course_title', I18n.t('application.field_required'));
      this.props.setInvalid('course_school', I18n.t('application.field_required'));
      this.props.setInvalid('description', I18n.t('application.field_required'));
      return false;
    }
    if (!this.slugPartsAreValid()) {
      this.props.setInvalid('course_title', I18n.t('application.field_required'));
      this.props.setInvalid('course_school', I18n.t('application.field_required'));
      this.props.setInvalid('description', I18n.t('application.field_required'));
      return false;
    }
    return true;
  },

  slugPartsAreValid() {
    if (!this.props.course.title.match(CourseUtils.courseSlugRegex())) { return false; }
    if (!this.props.course.school.match(CourseUtils.courseSlugRegex())) { return false; }
    if (this.props.course.term && !this.props.course.term.match(CourseUtils.courseSlugRegex())) { return false; }
    return true;
  },

  dateTimesAreValid() {
    const startDateTime = new Date(this.props.course.start);
    const endDateTime = new Date(this.props.course.end);
    const startEventTime = new Date(this.props.timeline_start);
    const endEventTime = new Date(this.props.timeline_end);
    if (startDateTime >= endDateTime || startEventTime >= endEventTime) {
      this.props.setInvalid('end', I18n.t('application.field_invalid_date_time'));
      return false;
    }
    if (CourseDateUtils.courseTooLong(this.props.course)) {
      this.props.setInvalid('end', I18n.t('courses.dates_too_long'));
      return false;
    }
    return true;
  },

  showCourseForm(programName) {
    this.updateCourseType('type', programName);

    return this.setState({
      showCourseForm: true,
      showWizardForm: false
    });
  },

  showCourseDates() {
    this.props.activateValidations();
    if (this.expectedStudentsIsValid() && this.titleSubjectAndDescriptionAreValid()) {
      this.props.resetValidations();
      return this.setState({
        showCourseDates: true,
        showCourseForm: false
      });
    }
  },

  backToCourseForm() {
    return this.setState({
      showCourseForm: true,
      showCourseDates: false
    });
  },

  showCourseTypes() {
    return this.setState({
      showWizardForm: true,
      showCourseForm: false
    });
  },

  showCloneChooser() {
    this.props.fetchAssignments(this.props.cloneableCourses[0].slug);
    return this.setState({ showCloneChooser: true });
  },

  cancelClone() {
    return this.setState({ showCloneChooser: false });
  },

  chooseNewCourse() {
    if (Features.wikiEd) {
      this.setState({ showCourseForm: true });
    } else {
      this.setState({ showWizardForm: true });
    }
  },

  useThisClass() {
    const select = this.courseSelect;
    const courseId = select.options[select.selectedIndex].getAttribute('data-id-key');
    this.props.cloneCourse(courseId, this.campaignParam(), this.state.copyCourseAssignments);
    return this.setState({ isSubmitting: true, shouldRedirect: true });
  },



  render() {
    if (this.props.loadingUserCourses) {
      return <div />;
    }
    // There are four fundamental states: NewOrClone, CourseForm, wizardForm and CloneChooser
    let showCourseForm;
    let showCloneChooser;
    let showNewOrClone;
    let showWizardForm;
    let showCourseDates;

    if (this.state.showWizardForm) {
      showWizardForm = true;
    } else if (this.state.showCourseDates) {
      showCourseDates = true;
    } else if (this.state.showCourseForm) {
      showCourseForm = true;
    } else if (this.state.showCloneChooser) {
      showCloneChooser = true;
      // If user has no courses, just open the CourseForm immediately because there are no cloneable courses.
    } else if (this.props.cloneableCourses.length === 0) {
      if (this.state.showCourseForm || Features.wikiEd) {
        showCourseForm = true;
      } else {
        showWizardForm = true;
      }
    } else {
      showNewOrClone = true;
    }

    let instructions;
    if (showNewOrClone) {
      instructions = CourseUtils.i18n('creator.new_or_clone', this.state.course_string_prefix);
    } else if (showCloneChooser) {
      instructions = CourseUtils.i18n('creator.choose_clone', this.state.course_string_prefix);
    } else if (showCourseForm) {
      instructions = CourseUtils.i18n('creator.intro', this.state.course_string_prefix);
    }

    let specialNotice;
    if (this.state.courseCreationNotice) {
      specialNotice = (
        <p className="timeline-warning" dangerouslySetInnerHTML={{ __html: this.state.courseCreationNotice }} />
      );
    }

    let formStyle;
    if (this.state.isSubmitting === true) {
      formStyle = { pointerEvents: 'none', opacity: 0.5 };
    }

    let courseFormClass = 'wizard__form';
    let courseWizard = 'wizard__program';
    let courseDates = 'wizard__dates';

    courseFormClass += showCourseForm ? '' : ' hidden';
    courseWizard += showWizardForm ? '' : ' hidden';
    courseDates += showCourseDates ? '' : ' hidden';

    const cloneOptions = showNewOrClone ? '' : ' hidden';
    const controlClass = `wizard__panel__controls ${courseDates}`;
    const selectClass = showCloneChooser ? '' : ' hidden';
    const options = this.props.cloneableCourses.map((course, i) => <option key={i} data-id-key={course.id} value={course.slug}>{course.title}</option>);
    const selectClassName = `select-container ${selectClass}`;
    const eventFormClass = this.state.showEventDates ? '' : 'hidden';
    const eventClass = `${eventFormClass}`;
    const reuseCourseSelect = <select id="reuse-existing-course-select" ref={(dropdown) => { this.courseSelect = dropdown; }} onChange={this.onDropdownChange}>{options}</select>;

    let showCheckbox;
    if (this.props.assignmentsWithoutUsers.length > 0) {
      showCheckbox = true;
    } else {
      showCheckbox = false;
    }
    const checkBoxLabel = (
      <span style={{ marginTop: '1vh' }}>
        <input id="copy_cloned_articles" type="checkbox" onChange={this.setCopyCourseAssignments}/>
        <label htmlFor="checkbox_id">{I18n.t('courses.creator.copy_courses_with_assignments')}</label>
      </span>
    );

    return (
      <Modal key="modal">
        <Notifications />
        <div className="container">
          <div className="wizard__panel active" style={formStyle}>
            <h3>{CourseUtils.i18n('creator.create_new', this.state.course_string_prefix)}</h3>
            {specialNotice}
            <p>{instructions}</p>
            <NewOrClone
              cloneClasss={cloneOptions}
              chooseNewCourseAction={this.chooseNewCourse}
              showCloneChooserAction={this.showCloneChooser}
              stringPrefix={this.state.course_string_prefix}
            />
            <CourseType
              wizardClass={courseWizard}
              wizardAction={this.showCourseForm}
            />
            <ReuseExistingCourse
              selectClassName={selectClassName}
              courseSelect={reuseCourseSelect}
              options={options}
              useThisClassAction={this.useThisClass}
              stringPrefix={this.state.course_string_prefix}
              cancelCloneAction={this.cancelClone}
              assignmentsWithoutUsers={showCheckbox}
              checkBoxLabel={checkBoxLabel}
            />
            <CourseForm
              courseFormClass={courseFormClass}
              stringPrefix={this.state.course_string_prefix}
              updateCourseAction={this.updateCourse}
              course={this.props.course}
              eventClass={eventClass}
              defaultCourse={this.state.default_course_type}
              updateCourseProps={this.props.updateCourse}
              next={this.showCourseDates}
              previous={this.showCourseTypes}
              backCondition={this.campaignParam()}
              tempCourseId={this.state.tempCourseId}
              firstErrorMessage={this.props.firstErrorMessage}
            />
            <CourseDates
              courseDateClass={courseDates}
              course={this.props.course}
              showTimeValues={this.state.use_start_and_end_times}
              showEventDates={this.showEventDates}
              showEventDatesState={this.state.showEventDates}
              stringPrefix={this.state.course_string_prefix}
              updateCourseProps={this.props.updateCourse}
              enableTimeline={this.props.courseCreator.useStartAndEndTimes}
            />
            <div className={controlClass}>
              <div className="left">
                <button onClick={this.backToCourseForm} className="dark button">Back</button>
                <p className="tempCourseIdText">{this.state.tempCourseId}</p>
              </div>
              <div className="right">
                <div><p className="red">{this.props.firstErrorMessage}</p></div>
                <Link className="button" to="/" id="course_cancel">{I18n.t('application.cancel')}</Link>
                <button onClick={this.saveCourse} className="dark button button__submit">{CourseUtils.i18n('creator.create_button', this.state.course_string_prefix)}</button>
              </div>
            </div>
          </div>
        </div>
      </Modal>
    );
  }
});

const mapStateToProps = state => ({
  course: state.course,
  courseCreator: state.courseCreator,
  cloneableCourses: getCloneableCourses(state),
  loadingUserCourses: state.userCourses.loading,
  validations: state.validations.validations,
  isValid: isValid(state),
  firstErrorMessage: firstValidationErrorMessage(state),
  assignmentsWithoutUsers: getAvailableArticles(state),
});

const mapDispatchToProps = ({
  fetchCampaign,
  fetchCoursesForUser,
  updateCourse,
  submitCourse,
  cloneCourse,
  setValid,
  setInvalid,
  checkCourseSlug,
  activateValidations,
  resetValidations,
  fetchAssignments
});

// exporting two difference ways as a testing hack.
export default connect(mapStateToProps, mapDispatchToProps)(CourseCreator);

export { CourseCreator };
