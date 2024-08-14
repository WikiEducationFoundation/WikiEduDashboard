import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';
import { includes } from 'lodash-es';

import { updateCourse as updateCourseAction } from '../../actions/course_actions';
import { fetchCampaign, submitCourse, cloneCourse } from '../../actions/course_creation_actions.js';
import { fetchCoursesForUser } from '../../actions/user_courses_actions.js';
import { setValid, setInvalid, checkCourseSlug, activateValidations, resetValidations } from '../../actions/validation_actions';
import { getCloneableCourses, isValid, firstValidationErrorMessage, } from '../../selectors';

import Notifications from '../common/notifications.jsx';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import CourseType from './course_type.jsx';
import NewOrClone from './new_or_clone.jsx';
import ReuseExistingCourse from './reuse_existing_course.jsx';
import CourseForm from './course_form.jsx';
import CourseDates from './course_dates.jsx';
import { fetchAssignments } from '../../actions/assignment_actions';

const CourseCreator = (props) => {
  const [tempCourseId, setTempCourseId] = useState('');
  const [showCourseForm, setShowCourseForm] = useState(false);
  const [showCloneChooser, setShowCloneChooser] = useState(false);

  const [showWizardForm, setShowWizardForm] = useState(false);
  const [showCourseDates, setShowCourseDates] = useState(false);
  const [copyCourseAssignments, setCopyCourseAssignments] = useState(false);
  const [courseCloneId, setCourseCloneId] = useState(null);

  const defaultCourseType = props.courseCreator.defaultCourseType;
  const courseStringPrefix = props.courseCreator.courseStringPrefix;
  const courseCreationNotice = props.courseCreator.courseCreationNotice;

  useEffect(() => {
    const campaignParam = CampaignParam();
    if (campaignParam) {
      props.fetchCampaign(campaignParam);
    }
    props.fetchCoursesForUser(window.currentUser.id);
  }, []);

  useEffect(() => {
    setTempCourseId(CourseUtils.generateTempId(props.course));
    handleCourse(props.course, props.isValid);
  }, [props.course, props.isValid]);

  const CampaignParam = () => {
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
        <button onClick={backFunction || backToCourseForm} className="dark button">{I18n.t('buttons.back')}</button>
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
        props.submitCourse({ course: cleanedCourse });
      }
    } else if (!props.validations.exists.valid) {
      // handle invalid state if needed
    }
  };

  const updateCourse = (key, value) => {
    props.updateCourseAction({ [key]: value });
    if (includes(['title', 'school', 'term'], key)) {
      props.setValid('exists');
    }
  };

  const updateCourseType = (key, value) => {
    props.updateCourseAction({ [key]: value });
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


  const backToCourseForm = () => {
    setShowCourseForm(true);
    setShowCourseDates(false);
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
    props.cloneCourse(courseCloneId, CampaignParam(), copyCourseAssignments);
  };

  if (props.loadingUserCourses || props.loadingCampaign) {
    return <div className="wizard__panel_loader">{I18n.t('application.loading')}</div>; // Replaced string literal
  }

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
      <div className="wizard__panel__background" />
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

const mapStateToProps = state => ({
  course: state.course,
  cloneableCourses: getCloneableCourses(state),
  courseCreator: state.courseCreator,
  loadingUserCourses: state.loadingUserCourses,
  loadingCampaign: state.loadingCampaign,
  isValid: isValid(state),
  firstErrorMessage: firstValidationErrorMessage(state),
});

const mapDispatchToProps = {
  updateCourse: updateCourseAction,
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

