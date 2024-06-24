import React, { useState, useEffect } from 'react';
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
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import CourseType from './course_type.jsx';
import NewOrClone from './new_or_clone.jsx';
import ReuseExistingCourse from './reuse_existing_course.jsx';
import CourseForm from './course_form.jsx';
import CourseDates from './course_dates.jsx';
import { fetchAssignments } from '../../actions/assignment_actions';
import { getScopingMethods } from '../util/scoping_methods';

const CourseCreator = (props) => {
  const [tempCourseId, setTempCourseId] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showCourseForm, setShowCourseForm] = useState(false);
  const [showCloneChooser, setShowCloneChooser] = useState(false);
  const [showEventDates, setShowEventDates] = useState(false);
  const [showWizardForm, setShowWizardForm] = useState(false);
  const [showCourseDates, setShowCourseDates] = useState(false);
  const [copyCourseAssignments, setCopyCourseAssignments] = useState(false);
  const [courseCloneId, setCourseCloneId] = useState(null);

  const defaultCourseType = props.courseCreator.defaultCourseType;
  const courseStringPrefix = props.courseCreator.courseStringPrefix;
  const useStartAndEndTimes = props.courseCreator.useStartAndEndTimes;
  const courseCreationNotice = props.courseCreator.courseCreationNotice;

  useEffect(() => {
    const campaignParam = campaignParam();
    if (campaignParam) {
      props.fetchCampaign(campaignParam);
    }
    props.fetchCoursesForUser(window.currentUser.id);
  }, []);

  useEffect(() => {
    setTempCourseId(CourseUtils.generateTempId(props.course));
    handleCourse(props.course, props.isValid);
  }, [props.course, props.isValid]);

  const campaignParam = () => {
    const campaignParam = window.location.search.match(/\?.*?campaign_slug=(.*?)(?:$|&)/);
    if (campaignParam) {
      return campaignParam[1];
    }
  };

  const onDropdownChange = (event) => {
    setCourseCloneId(event.id);
    props.fetchAssignments(event.value);
  };

  const setCopyCourseAssignmentsHandler = (e) => {
    setCopyCourseAssignments(e.target.checked);
  };

  const getWizardController = ({ hidden, backFunction }) => (
    <div className={`wizard__panel__controls ${hidden ? 'hidden' : ''}`}>
      <div className="left">
        <button onClick={backFunction || backToCourseForm} className="dark button">Back</button>
        <p className="tempCourseIdText">{tempCourseId}</p>
      </div>
      <div className="right">
        <div><p className="red">{props.firstErrorMessage}</p></div>
        <Link className="button" to="/" id="course_cancel">{I18n.t('application.cancel')}</Link>
        <button onClick={saveCourse} className="dark button button__submit">{CourseUtils.i18n('creator.create_button', courseStringPrefix)}</button>
      </div>
    </div>
  );

  const saveCourse = () => {
    props.activateValidations();
    if (props.isValid && dateTimesAreValid()) {
      setIsSubmitting(true);
      props.setInvalid(
        'exists',
        CourseUtils.i18n('creator.checking_for_uniqueness', courseStringPrefix),
        true
      );
      return props.checkCourseSlug(CourseUtils.generateTempId(props.course));
    }
  };

  const handleCourse = (course, isValidProp) => {
    if (isValidProp) {
      if (course.slug) {
        if (defaultCourseType === 'ClassroomProgramCourse') {
          window.location = `/courses/${course.slug}/timeline/wizard`;
        } else {
          window.location = `/courses/${course.slug}`;
        }
      } else {
        const cleanedCourse = CourseUtils.cleanupCourseSlugComponents(course);
        props.submitCourse({ course: cleanedCourse }, () => setIsSubmitting(false));
      }
    } else if (!props.validations.exists.valid) {
      setIsSubmitting(false);
    }
  };

  const showEventDate = () => {
    setShowEventDates(!showEventDates);
  };

  const updateCourse = (key, value) => {
    props.updateCourse({ [key]: value });
    if (includes(['title', 'school', 'term'], key)) {
      props.setValid('exists');
    }
  };

  const updateCourseType = (key, value) => {
    props.updateCourse({ [key]: value });
  };

  const expectedStudentsIsValid = () => {
    if (props.course.expected_students === '0' && defaultCourseType === 'ClassroomProgramCourse') {
      props.setInvalid('expected_students', I18n.t('application.field_required'));
      return false;
    }
    return true;
  };

  const titleSubjectAndDescriptionAreValid = () => {
    if (props.course.title === '' || props.course.school === '' || props.course.description === '') {
      props.setInvalid('course_title', I18n.t('application.field_required'));
      props.setInvalid('course_school', I18n.t('application.field_required'));
      props.setInvalid('description', I18n.t('application.field_required'));
      return false;
    }
    if (!slugPartsAreValid()) {
      props.setInvalid('course_title', I18n.t('application.field_required'));
      props.setInvalid('course_school', I18n.t('application.field_required'));
      props.setInvalid('description', I18n.t('application.field_required'));
      return false;
    }
    return true;
  };

  const slugPartsAreValid = () => {
    if (!props.course.title.match(CourseUtils.courseSlugRegex())) { return false; }
    if (!props.course.school.match(CourseUtils.courseSlugRegex())) { return false; }
    if (props.course.term && !props.course.term.match(CourseUtils.courseSlugRegex())) { return false; }
    return true;
  };

  const dateTimesAreValid = () => {
    const startDateTime = new Date(props.course.start);
    const endDateTime = new Date(props.course.end);
    const startEventTime = new Date(props.timeline_start);
    const endEventTime = new Date(props.timeline_end);
    if (startDateTime >= endDateTime || startEventTime >= endEventTime) {
      props.setInvalid('end', I18n.t('application.field_invalid_date_time'));
      return false;
    }
    if (CourseDateUtils.courseTooLong(props.course)) {
      props.setInvalid('end', I18n.t('courses.dates_too_long'));
      return false;
    }
    return true;
  };

  const showCourseFormHandler = (programName) => {
    updateCourseType('type', programName);
    setShowCourseForm(true);
    setShowWizardForm(false);
  };

  const showCourseDatesHandler = () => {
    props.activateValidations();
    if (expectedStudentsIsValid() && titleSubjectAndDescriptionAreValid()) {
      props.resetValidations();
      setShowCourseDates(true);
      setShowCourseForm(false);
    }
  };

  const showCourseScopingHandler = () => {
    props.activateValidations();
    if (expectedStudentsIsValid() && titleSubjectAndDescriptionAreValid() && dateTimesAreValid()) {
      props.resetValidations();
      setShowCourseDates(false);
      setShowCourseForm(false);
      setShowWizardForm(false);
    }
  };

  const backToCourseForm = () => {
    setShowCourseForm(true);
    setShowCourseDates(false);
  };

  const showCourseTypesHandler = () => {
    setShowWizardForm(true);
    setShowCourseForm(false);
  };

  const showCloneChooserHandler = () => {
    props.fetchAssignments(props.cloneableCourses[0].slug);
    setShowCloneChooser(true);
  };

  const cancelClone = () => {
    setShowCloneChooser(false);
  };

  const chooseNewCourseHandler = () => {
    if (Features.wikiEd) {
      setShowCourseForm(true);
    } else {
      setShowWizardForm(true);
    }
  };

  const useThisClassHandler = () => {
    props.cloneCourse(courseCloneId, campaignParam(), copyCourseAssignments);
    setIsSubmitting(true);
  };

  if (props.loadingUserCourses || props.loadingCampaign) {
    return <div className="wizard__panel_loader">Loading...</div>;
  }

  const scopingMethods = getScopingMethods();

  let inner;
  if (showCourseForm) {
    inner = (
      <>
        <Notifications />
        <CourseForm
          course={props.course}
          courseCreator={props.courseCreator}
          updateCourse={updateCourse}
          setValid={props.setValid}
          setInvalid={props.setInvalid}
          activateValidations={props.activateValidations}
          isValid={props.isValid}
          firstErrorMessage={props.firstErrorMessage}
        />
        {getWizardController({ hidden: false })}
      </>
    );
  } else if (showCourseDates) {
    inner = (
      <>
        <Notifications />
        <CourseDates
          course={props.course}
          courseCreator={props.courseCreator}
          updateCourse={updateCourse}
          setValid={props.setValid}
          setInvalid={props.setInvalid}
          activateValidations={props.activateValidations}
          isValid={props.isValid}
          firstErrorMessage={props.firstErrorMessage}
        />
        {getWizardController({ hidden: false })}
      </>
    );
  } else if (showCloneChooser) {
    inner = (
      <ReuseExistingCourse
        course={props.course}
        courseCreator={props.courseCreator}
        updateCourse={updateCourse}
        useThisClass={useThisClassHandler}
        cancelClone={cancelClone}
        onDropdownChange={onDropdownChange}
        cloneableCourses={props.cloneableCourses}
        copyCourseAssignments={copyCourseAssignments}
        setCopyCourseAssignments={setCopyCourseAssignmentsHandler}
      />
    );
  } else if (showWizardForm) {
    inner = (
      <NewOrClone
        courseCreator={props.courseCreator}
        chooseNewCourse={chooseNewCourseHandler}
        showCloneChooser={showCloneChooserHandler}
      />
    );
  } else {
    inner = (
      <CourseType
        courseCreator={props.courseCreator}
        showCourseForm={showCourseFormHandler}
      />
    );
  }

  return (
    <div id="course_creation">
      {courseCreationNotice}
      <div className="wizard__panel active">
        {inner}
      </div>
      <div className="wizard__panel__background"></div>
    </div>
  );
};

CourseCreator.propTypes = {
  course: PropTypes.object.isRequired,
  cloneableCourses: PropTypes.array,
  courseCreator: PropTypes.object.isRequired,
  updateCourse: PropTypes.func.isRequired,
  submitCourse: PropTypes.func.isRequired,
  setValid: PropTypes.func.isRequired,
  setInvalid: PropTypes.func.isRequired,
  activateValidations: PropTypes.func.isRequired,
  resetValidations: PropTypes.func.isRequired,
  checkCourseSlug: PropTypes.func.isRequired,
  fetchCampaign: PropTypes.func.isRequired,
  cloneCourse: PropTypes.func.isRequired,
  fetchCoursesForUser: PropTypes.func.isRequired,
  fetchAssignments: PropTypes.func.isRequired,
  loadingUserCourses: PropTypes.bool,
  loadingCampaign: PropTypes.bool,
  isValid: PropTypes.bool,
  firstErrorMessage: PropTypes.string,
};

const mapStateToProps = (state) => ({
  course: state.course,
  cloneableCourses: getCloneableCourses(state),
  courseCreator: state.courseCreator,
  loadingUserCourses: state.loadingUserCourses,
  loadingCampaign: state.loadingCampaign,
  isValid: isValid(state),
  firstErrorMessage: firstValidationErrorMessage(state),
});

const mapDispatchToProps = {
  updateCourse,
  submitCourse,
  setValid,
  setInvalid,
  activateValidations,
  resetValidations,
  checkCourseSlug,
  fetchCampaign,
  cloneCourse,
  fetchCoursesForUser,
  fetchAssignments
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseCreator);
