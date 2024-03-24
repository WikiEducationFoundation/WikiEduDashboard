import React, { useEffect } from 'react';
import { useSelector, connect } from 'react-redux';
import { parse } from 'query-string';
import OverviewStats from './overview_stats.jsx';
import AvailableActions from './available_actions.jsx';
import Description from './description.jsx';
import Milestones from './milestones.jsx';
import Details from './details.jsx';
import ThisWeek from './this_week.jsx';
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.jsx';
import SyllabusUpload from './syllabus-upload.jsx';
import AdminQuickActions from './admin_quick_actions.jsx';
import MyArticles from './my_articles/containers';
import MyExercises from './my_exercises/containers/Container';
import Modal from '../common/modal.jsx';
import StatisticsUpdateInfo from './statistics_update_info.jsx';
import OverviewStatsTabs from '../common/overview_stats_tabs';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { deleteCourse, updateCourse, resetCourse, persistCourse, nameHasChanged, updateClonedCourse, refetchCourse, greetStudents } from '../../actions/course_actions';
import { fetchOnboardingAlert } from '../../actions/course_alert_actions';
import { fetchTags } from '../../actions/tag_actions';
import { addValidation, setValid, setInvalid, activateValidations } from '../../actions/validation_actions';
import { getStudentUsers, getWeeksArray, getAllWeeksArray, firstValidationErrorMessage, isValid } from '../../selectors';
import { useLocation } from 'react-router-dom';

const Overview = (props) => {
  const students = useSelector(state => getStudentUsers(state));
  const campaigns = useSelector(state => state.campaigns.campaigns);
  const weeks = useSelector(state => getWeeksArray(state));
  const allWeeks = useSelector(state => getAllWeeksArray(state));
  const loading = useSelector(state => state.timeline.loading || state.course.loading);
  const firstErrorMessage = useSelector(state => firstValidationErrorMessage(state));
  const isValidCourse = useSelector(state => isValid(state));
  const courseCreationNotice = useSelector(state => state.courseCreator.courseCreationNotice);
  const location = useLocation();
  const course = props.course;
  const currentUser = props.current_user;

  useEffect(() => {
    document.title = course.title;
    if (currentUser.admin) {
      props.fetchOnboardingAlert(course);
      props.fetchTags(props.course_id);
    }
  }, []);

  if (course.cloned_status === 1) {
    return (
      <CourseClonedModal
        course={course}
        initiateConfirm={props.initiateConfirm}
        deleteCourse={props.deleteCourse}
        updateCourse={props.updateCourse}
        updateClonedCourse={props.updateClonedCourse}
        currentUser={currentUser}
        firstErrorMessage={firstErrorMessage}
        isValid={isValidCourse}
        setValid={props.setValid}
        setInvalid={props.setInvalid}
        addValidation={props.addValidation}
        activateValidations={props.activateValidations}
        courseCreationNotice={courseCreationNotice}
      />
    );
  }

  let syllabusUpload;
  const query = parse(location.search);
  if (query.syllabus_upload === 'true' && currentUser.admin) {
    syllabusUpload = (
      <Modal modalClass="course__syllabus-upload">
        <SyllabusUpload course={course} />
      </Modal>
    );
  }

  let thisWeek;
  const noWeeks = weeks.length === 0;
  if (!course.legacy && !noWeeks) {
    thisWeek = (
      <ThisWeek
        course={course}
        weeks={weeks}
        current_user={currentUser}
      />
    );
  }

  const primaryContent = loading ? (
    <Loading />
  ) : (
    <div>
      <Description
        description={course.description}
        title={course.title}
        course_id={props.course_id}
        current_user={currentUser}
        updateCourse={props.updateCourse}
        resetState={props.resetCourse}
        persistCourse={props.persistCourse}
        nameHasChanged={props.nameHasChanged}
      />
      {thisWeek}
    </div>
  );

  let userArticles;
  // const isWikidataCourse = course.home_wiki && course.home_wiki.project === 'wikidata';
  if (currentUser.isEnrolled && course.id) {
    userArticles = (
      <>
        <MyExercises trainingLibrarySlug={course.training_library_slug} />
        <MyArticles
          course={course}
          course_id={props.course_id}
          current_user={currentUser}
        />
      </>
    );
  }

  const sidebar = course.id ? (
    <div className="sidebar">
      {
        Features.wikiEd && currentUser.isStaff && (
          <AdminQuickActions
            course={course}
            current_user={currentUser}
            persistCourse={props.persistCourse}
            greetStudents={props.greetStudents}
          />
        )
      }
      <Details
        {...props}
        students={students}
        course={course}
        current_user={currentUser}
        campaigns={campaigns}
        updateCourse={props.updateCourse}
        resetState={props.resetCourse}
        persistCourse={props.persistCourse}
        nameHasChanged={props.nameHasChanged}
        refetchCourse={props.refetchCourse}
        firstErrorMessage={firstErrorMessage}
      />
      <AvailableActions course={course} current_user={currentUser} updateCourse={props.updateCourse} courseCreationNotice={courseCreationNotice} />
      <Milestones timelineStart={course.timeline_start} weeks={weeks} allWeeks={allWeeks} course={course} />
    </div>
  ) : (
    <div className="sidebar" />
  );

  let overviewStatsTabs;
  if (course.course_stats && course.course_stats.stats_hash) {
    overviewStatsTabs = <OverviewStatsTabs statistics={course.course_stats.stats_hash} />;
  }

  return (
    <section className="overview container">
      {syllabusUpload}
      <OverviewStats course={course} />
      {overviewStatsTabs}
      <StatisticsUpdateInfo course={course} />
      {userArticles}
      <div className="primary">
        {primaryContent}
      </div>
      {sidebar}
    </section>
  );
};

const mapDispatchToProps = {
  initiateConfirm,
  deleteCourse,
  updateCourse,
  resetCourse,
  persistCourse,
  nameHasChanged,
  updateClonedCourse,
  fetchTags,
  refetchCourse,
  addValidation,
  setValid,
  setInvalid,
  activateValidations,
  fetchOnboardingAlert,
  greetStudents
};

export default connect(null, mapDispatchToProps)(Overview);
