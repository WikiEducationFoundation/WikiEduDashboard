import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { parse } from 'query-string';
import { useLocation } from 'react-router-dom';
import PropTypes from 'prop-types';
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
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { deleteCourse, updateCourse, resetCourse, persistCourse, nameHasChanged, updateClonedCourse, refetchCourse, greetStudents } from '../../actions/course_actions';
import { fetchOnboardingAlert } from '../../actions/course_alert_actions';
import { fetchTags } from '../../actions/tag_actions';
import { addValidation, setValid, setInvalid, activateValidations } from '../../actions/validation_actions';
import { getWeeksArray, getAllWeeksArray, firstValidationErrorMessage, isValid as selectIsValid } from '../../selectors';
import OverviewStatsTabs from '../common/overview_stats_tabs';

const Overview = ({ course, current_user, course_id }) => {
  const dispatch = useDispatch();
  const location = useLocation();
  const weeks = useSelector(getWeeksArray);
  const allWeeks = useSelector(getAllWeeksArray);
  const loading = useSelector(state => state.timeline.loading || state.course.loading);
  const firstErrorMessage = useSelector(firstValidationErrorMessage);
  const isValid = useSelector(selectIsValid);
  const courseCreationNotice = useSelector(state => state.courseCreator.courseCreationNotice);

  useEffect(() => {
    document.title = course.title;
    if (current_user.admin) {
      dispatch(fetchOnboardingAlert(course));
      dispatch(fetchTags(course_id));
    }
  }, [course, current_user, course_id, dispatch]);

  if (course.cloned_status === 1 || course.cloned_status === 3) {
    return (
      <CourseClonedModal
        course={course}
        initiateConfirm={() => dispatch(initiateConfirm())}
        deleteCourse={() => dispatch(deleteCourse())}
        updateCourse={data => dispatch(updateCourse(data))}
        updateClonedCourse={data => dispatch(updateClonedCourse(data))}
        currentUser={current_user}
        firstErrorMessage={firstErrorMessage}
        isValid={isValid}
        setValid={() => dispatch(setValid())}
        setInvalid={() => dispatch(setInvalid())}
        addValidation={data => dispatch(addValidation(data))}
        activateValidations={() => dispatch(activateValidations())}
        courseCreationNotice={courseCreationNotice}
      />
    );
  }

  const query = parse(location.search);
  const syllabusUpload = query.syllabus_upload === 'true' && current_user.admin && (
    <Modal modalClass="course__syllabus-upload">
      <SyllabusUpload course={course} />
    </Modal>
  );

  const noWeeks = weeks.length === 0;
  const thisWeek = !course.legacy && !noWeeks && (
    <ThisWeek
      course={course}
      weeks={weeks}
      current_user={current_user}
    />
  );

  const primaryContent = loading ? (
    <Loading />
  ) : (
    <div>
      <Description
        description={course.description}
        title={course.title}
        course_id={course_id}
        current_user={current_user}
        updateCourse={data => dispatch(updateCourse(data))}
        resetState={() => dispatch(resetCourse())}
        persistCourse={data => dispatch(persistCourse(data))}
        nameHasChanged={data => dispatch(nameHasChanged(data))}
      />
      {thisWeek}
    </div>
  );

  const userArticles = current_user.isEnrolled && course.id && (
    <>
      <MyExercises trainingLibrarySlug={course.training_library_slug} />
      <MyArticles
        course={course}
        course_id={course_id}
        current_user={current_user}
      />
    </>
  );

  const sidebar = course.id ? (
    <div className="sidebar">
      {Features.wikiEd && current_user.admin && (
        <AdminQuickActions
          course={course}
          current_user={current_user}
          persistCourse={data => dispatch(persistCourse(data))}
          greetStudents={() => dispatch(greetStudents())}
        />
      )}
      <Details
        course={course}
        current_user={current_user}
        updateCourse={data => dispatch(updateCourse(data))}
        resetState={() => dispatch(resetCourse())}
        persistCourse={data => dispatch(persistCourse(data))}
        nameHasChanged={data => dispatch(nameHasChanged(data))}
        refetchCourse={() => dispatch(refetchCourse())}
      />
      <AvailableActions
        course={course}
        current_user={current_user}
        updateCourse={data => dispatch(updateCourse(data))}
        courseCreationNotice={courseCreationNotice}
      />
      <Milestones
        timelineStart={course.timeline_start}
        weeks={weeks}
        allWeeks={allWeeks}
        course={course}
      />
    </div>
  ) : (
    <div className="sidebar" />
  );

  const overviewStatsTabs = course.course_stats && course.course_stats.stats_hash && (
    <OverviewStatsTabs course={course} statistics={course.course_stats.stats_hash} />
  );

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

Overview.propTypes = {
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  course_id: PropTypes.string,
};

export default Overview;
